#[path = "bindings.rs"]
mod bindings;

use bindings::*;
use libloading::Library;
use std::{
    env,
    ffi::{CStr, CString},
    ptr::{self, NonNull},
    sync::{Arc, OnceLock},
};
use thiserror::Error;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum SymbolVersion {
    // Apple's libicucore exports stable, unsuffixed names.
    Unversioned,
    // Standard ICU builds suffix exported symbols with the major version.
    Major(u8),
}

impl SymbolVersion {
    fn symbol(self, base: &str) -> Vec<u8> {
        let name = match self {
            Self::Unversioned => base.to_owned(),
            Self::Major(major) => format!("{base}_{major}"),
        };
        let mut bytes = name.into_bytes();
        bytes.push(0);
        bytes
    }
}

impl std::fmt::Display for SymbolVersion {
    fn fmt(&self, formatter: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Unversioned => formatter.write_str("unversioned"),
            Self::Major(major) => write!(formatter, "major-suffixed ({major})"),
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
struct IcuVersion {
    major: u8,
    minor: u8,
    milli: u8,
    micro: u8,
}

impl std::fmt::Display for IcuVersion {
    fn fmt(&self, formatter: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            formatter,
            "{}.{}.{}.{}",
            self.major, self.minor, self.milli, self.micro
        )
    }
}

#[derive(Debug, Clone, Error)]
pub(crate) enum Error {
    #[error("could not load ICU {kind} library; tried {tried:?}: {last_error}")]
    LibraryNotFound {
        kind: &'static str,
        tried: Vec<String>,
        last_error: String,
    },
    #[error("ICU library does not export a supported u_getVersion symbol")]
    VersionSymbolNotFound,
    #[error("ICU symbol {0} is missing")]
    SymbolNotFound(String),
    #[error("ICU call failed with {name} ({code})")]
    Icu { code: i32, name: String },
    #[error("ICU returned a null calendar without an error status")]
    NullCalendar,
    #[error("ICU returned a null number formatter without an error status")]
    NullNumberFormatter,
    #[error("string contains an interior NUL byte")]
    InteriorNul,
}

#[derive(Clone)]
pub(crate) struct Icu {
    resolved: Arc<ResolvedIcu>,
}

struct ResolvedIcu {
    // The libraries must outlive every copied function pointer below.
    _libraries: LoadedLibraries,
    version: IcuVersion,
    symbol_version: SymbolVersion,
    common: CommonFunctions,
    calendar: CalendarFunctions,
    number: NumberFunctions,
}

struct LoadedLibraries {
    _common: Library,
    _internationalization: Option<Library>,
}

struct CommonFunctions {
    error_name: UErrorName,
}

struct CalendarFunctions {
    open: UcalOpen,
    close: UcalClose,
    set_millis: UcalSetMillis,
    get_millis: UcalGetMillis,
    set_date: UcalSetDate,
    set_date_time: UcalSetDateTime,
    get: UcalGet,
    in_daylight_time: UcalInDaylightTime,
}

struct NumberFunctions {
    open: UnumOpen,
    close: UnumClose,
    format_double: UnumFormatDouble,
    format_double_currency: UnumFormatDoubleCurrency,
}

static ICU: OnceLock<Result<Icu, Error>> = OnceLock::new();

impl Icu {
    pub(crate) fn load() -> Result<Self, Error> {
        ICU.get_or_init(Self::resolve).clone()
    }

    fn resolve() -> Result<Self, Error> {
        let common_library = load_library("common", "OFFI_ICU_UC_LIB", common_candidates(None))?;
        let (symbol_version, get_version) = find_version_function(&common_library)?;

        let mut raw_version: UVersionInfo = [0; 4];
        unsafe { get_version(raw_version.as_mut_ptr()) };
        let version = IcuVersion {
            major: raw_version[0],
            minor: raw_version[1],
            milli: raw_version[2],
            micro: raw_version[3],
        };

        let common = CommonFunctions {
            error_name: unsafe { resolve(&common_library, symbol_version, "u_errorName")? },
        };

        let internationalization_library =
            if has_symbol(&common_library, symbol_version, "ucal_open") {
                None
            } else {
                Some(load_library(
                    "internationalization",
                    "OFFI_ICU_I18N_LIB",
                    i18n_candidates(Some(version.major)),
                )?)
            };
        let symbols = internationalization_library
            .as_ref()
            .unwrap_or(&common_library);

        let calendar = CalendarFunctions {
            open: unsafe { resolve(symbols, symbol_version, "ucal_open")? },
            close: unsafe { resolve(symbols, symbol_version, "ucal_close")? },
            set_millis: unsafe { resolve(symbols, symbol_version, "ucal_setMillis")? },
            get_millis: unsafe { resolve(symbols, symbol_version, "ucal_getMillis")? },
            set_date: unsafe { resolve(symbols, symbol_version, "ucal_setDate")? },
            set_date_time: unsafe { resolve(symbols, symbol_version, "ucal_setDateTime")? },
            get: unsafe { resolve(symbols, symbol_version, "ucal_get")? },
            in_daylight_time: unsafe { resolve(symbols, symbol_version, "ucal_inDaylightTime")? },
        };
        let number = NumberFunctions {
            open: unsafe { resolve(symbols, symbol_version, "unum_open")? },
            close: unsafe { resolve(symbols, symbol_version, "unum_close")? },
            format_double: unsafe { resolve(symbols, symbol_version, "unum_formatDouble")? },
            format_double_currency: unsafe {
                resolve(symbols, symbol_version, "unum_formatDoubleCurrency")?
            },
        };

        Ok(Self {
            resolved: Arc::new(ResolvedIcu {
                _libraries: LoadedLibraries {
                    _common: common_library,
                    _internationalization: internationalization_library,
                },
                version,
                symbol_version,
                common,
                calendar,
                number,
            }),
        })
    }

    pub(crate) fn version(&self) -> String {
        self.resolved.version.to_string()
    }

    pub(crate) fn symbol_version(&self) -> String {
        self.resolved.symbol_version.to_string()
    }

    fn check_status(&self, status: UErrorCode) -> Result<(), Error> {
        if status.0 <= 0 {
            return Ok(());
        }
        let name = unsafe {
            let pointer = (self.resolved.common.error_name)(status);
            if pointer.is_null() {
                "unknown ICU error".to_owned()
            } else {
                CStr::from_ptr(pointer).to_string_lossy().into_owned()
            }
        };
        Err(Error::Icu {
            code: status.0,
            name,
        })
    }
}

pub(crate) struct IcuCalendar {
    rep: NonNull<UCalendar>,
    icu: Icu,
}

// SAFETY: the handle has unique ownership and is never accessed concurrently;
// moving that ownership to another Ruby thread does not invalidate it.
unsafe impl Send for IcuCalendar {}

impl Drop for IcuCalendar {
    fn drop(&mut self) {
        unsafe { (self.icu.resolved.calendar.close)(self.rep.as_ptr()) };
    }
}

impl IcuCalendar {
    pub(crate) fn open(zone_id: &str, locale: &str) -> Result<Self, Error> {
        let icu = Icu::load()?;
        let zone_id = zone_id.encode_utf16().collect::<Vec<_>>();
        let locale = CString::new(locale).map_err(|_| Error::InteriorNul)?;
        let mut status = UErrorCode::U_ZERO_ERROR;
        let rep = unsafe {
            (icu.resolved.calendar.open)(
                zone_id.as_ptr(),
                zone_id.len() as i32,
                locale.as_ptr(),
                UCalendarType::UCAL_GREGORIAN,
                &mut status,
            )
        };
        icu.check_status(status)?;
        let rep = NonNull::new(rep).ok_or(Error::NullCalendar)?;
        Ok(Self { rep, icu })
    }

    pub(crate) fn version(&self) -> String {
        self.icu.version()
    }

    pub(crate) fn symbol_version(&self) -> String {
        self.icu.symbol_version()
    }

    pub(crate) fn set_millis(&self, date_time: f64) -> Result<(), Error> {
        let mut status = UErrorCode::U_ZERO_ERROR;
        unsafe {
            (self.icu.resolved.calendar.set_millis)(self.rep.as_ptr(), date_time, &mut status)
        };
        self.icu.check_status(status)
    }

    pub(crate) fn millis(&self) -> Result<f64, Error> {
        let mut status = UErrorCode::U_ZERO_ERROR;
        let millis =
            unsafe { (self.icu.resolved.calendar.get_millis)(self.rep.as_ptr(), &mut status) };
        self.icu.check_status(status)?;
        Ok(millis)
    }

    pub(crate) fn set_date(&self, year: i32, month: i32, day: i32) -> Result<(), Error> {
        let mut status = UErrorCode::U_ZERO_ERROR;
        unsafe {
            (self.icu.resolved.calendar.set_date)(self.rep.as_ptr(), year, month, day, &mut status)
        };
        self.icu.check_status(status)
    }

    pub(crate) fn set_date_time(
        &self,
        year: i32,
        month: i32,
        day: i32,
        hour: i32,
        minute: i32,
        second: i32,
    ) -> Result<(), Error> {
        let mut status = UErrorCode::U_ZERO_ERROR;
        unsafe {
            (self.icu.resolved.calendar.set_date_time)(
                self.rep.as_ptr(),
                year,
                month,
                day,
                hour,
                minute,
                second,
                &mut status,
            )
        };
        self.icu.check_status(status)
    }

    pub(crate) fn field(&self, field: CalendarField) -> Result<i32, Error> {
        let mut status = UErrorCode::U_ZERO_ERROR;
        let value = unsafe {
            (self.icu.resolved.calendar.get)(self.rep.as_ptr(), field.into_raw(), &mut status)
        };
        self.icu.check_status(status)?;
        Ok(value)
    }

    pub(crate) fn in_daylight_time(&self) -> Result<bool, Error> {
        let mut status = UErrorCode::U_ZERO_ERROR;
        let result = unsafe {
            (self.icu.resolved.calendar.in_daylight_time)(self.rep.as_ptr(), &mut status)
        };
        self.icu.check_status(status)?;
        Ok(result != 0)
    }
}

#[derive(Debug, Clone, Copy)]
pub(crate) enum CalendarField {
    Era,
    Year,
    Month,
    DayOfMonth,
    HourOfDay,
    Minute,
    Second,
    Millisecond,
    ZoneOffset,
    DstOffset,
}

impl CalendarField {
    fn into_raw(self) -> UCalendarDateFields {
        match self {
            Self::Era => UCalendarDateFields::UCAL_ERA,
            Self::Year => UCalendarDateFields::UCAL_YEAR,
            Self::Month => UCalendarDateFields::UCAL_MONTH,
            Self::DayOfMonth => UCalendarDateFields::UCAL_DATE,
            Self::HourOfDay => UCalendarDateFields::UCAL_HOUR_OF_DAY,
            Self::Minute => UCalendarDateFields::UCAL_MINUTE,
            Self::Second => UCalendarDateFields::UCAL_SECOND,
            Self::Millisecond => UCalendarDateFields::UCAL_MILLISECOND,
            Self::ZoneOffset => UCalendarDateFields::UCAL_ZONE_OFFSET,
            Self::DstOffset => UCalendarDateFields::UCAL_DST_OFFSET,
        }
    }
}

pub(crate) struct IcuNumberFormatter {
    rep: NonNull<UNumberFormat>,
    icu: Icu,
}

// SAFETY: the handle has unique ownership and is never accessed concurrently;
// moving that ownership to another Ruby thread does not invalidate it.
unsafe impl Send for IcuNumberFormatter {}

impl Drop for IcuNumberFormatter {
    fn drop(&mut self) {
        unsafe { (self.icu.resolved.number.close)(self.rep.as_ptr()) };
    }
}

impl IcuNumberFormatter {
    pub(crate) fn open(locale: &str, style: NumberFormatStyle) -> Result<Self, Error> {
        let icu = Icu::load()?;
        let locale = CString::new(locale).map_err(|_| Error::InteriorNul)?;
        let mut status = UErrorCode::U_ZERO_ERROR;
        let rep = unsafe {
            (icu.resolved.number.open)(
                style.into_raw(),
                ptr::null(),
                0,
                locale.as_ptr(),
                ptr::null_mut(),
                &mut status,
            )
        };
        icu.check_status(status)?;
        let rep = NonNull::new(rep).ok_or(Error::NullNumberFormatter)?;
        Ok(Self { rep, icu })
    }

    pub(crate) fn format(&self, number: f64) -> Result<String, Error> {
        self.format_uchar(|buffer, capacity, status| unsafe {
            (self.icu.resolved.number.format_double)(
                self.rep.as_ptr(),
                number,
                buffer,
                capacity,
                ptr::null_mut(),
                status,
            )
        })
    }

    pub(crate) fn format_currency(&self, number: f64, currency: &str) -> Result<String, Error> {
        let mut currency = currency.encode_utf16().collect::<Vec<_>>();
        currency.push(0);
        self.format_uchar(|buffer, capacity, status| unsafe {
            (self.icu.resolved.number.format_double_currency)(
                self.rep.as_ptr(),
                number,
                currency.as_mut_ptr(),
                buffer,
                capacity,
                ptr::null_mut(),
                status,
            )
        })
    }

    fn format_uchar(
        &self,
        mut call: impl FnMut(*mut u16, i32, *mut UErrorCode) -> i32,
    ) -> Result<String, Error> {
        let mut status = UErrorCode::U_ZERO_ERROR;
        let needed = call(ptr::null_mut(), 0, &mut status);
        if status != UErrorCode::U_BUFFER_OVERFLOW_ERROR {
            self.icu.check_status(status)?;
        }

        let mut output = vec![0u16; needed.max(1) as usize];
        status = UErrorCode::U_ZERO_ERROR;
        let written = call(output.as_mut_ptr(), output.len() as i32, &mut status);
        self.icu.check_status(status)?;
        output.truncate(written as usize);
        Ok(String::from_utf16_lossy(&output))
    }
}

#[derive(Debug, Clone, Copy)]
pub(crate) enum NumberFormatStyle {
    Decimal,
    Currency,
    CurrencyIso,
    CurrencyPlural,
}

impl NumberFormatStyle {
    fn into_raw(self) -> UNumberFormatStyle {
        match self {
            Self::Decimal => UNumberFormatStyle::UNUM_DECIMAL,
            Self::Currency => UNumberFormatStyle::UNUM_CURRENCY,
            Self::CurrencyIso => UNumberFormatStyle::UNUM_CURRENCY_ISO,
            Self::CurrencyPlural => UNumberFormatStyle::UNUM_CURRENCY_PLURAL,
        }
    }
}

fn find_version_function(library: &Library) -> Result<(SymbolVersion, UGetVersion), Error> {
    let mut styles = Vec::with_capacity(62);
    styles.push(SymbolVersion::Unversioned);
    styles.extend((40..=100).rev().map(SymbolVersion::Major));

    for style in styles {
        if let Ok(function) = unsafe { resolve::<UGetVersion>(library, style, "u_getVersion") } {
            return Ok((style, function));
        }
    }
    Err(Error::VersionSymbolNotFound)
}

fn has_symbol(library: &Library, style: SymbolVersion, base: &str) -> bool {
    let name = style.symbol(base);
    unsafe { library.get::<*const ()>(&name).is_ok() }
}

unsafe fn resolve<T: Copy>(
    library: &Library,
    style: SymbolVersion,
    base: &str,
) -> Result<T, Error> {
    let name = style.symbol(base);
    unsafe { library.get::<T>(&name) }
        .map(|symbol| *symbol)
        .map_err(|_| Error::SymbolNotFound(String::from_utf8_lossy(&name[..name.len() - 1]).into()))
}

fn load_library(
    kind: &'static str,
    override_variable: &str,
    candidates: Vec<String>,
) -> Result<Library, Error> {
    let names = env::var(override_variable)
        .ok()
        .map(|name| vec![name])
        .unwrap_or(candidates);
    let mut last_error = "no candidate names".to_owned();

    for name in &names {
        match unsafe { Library::new(name) } {
            Ok(library) => return Ok(library),
            Err(error) => last_error = error.to_string(),
        }
    }

    Err(Error::LibraryNotFound {
        kind,
        tried: names,
        last_error,
    })
}

fn common_candidates(preferred_major: Option<u8>) -> Vec<String> {
    library_candidates("icuuc", preferred_major)
}

fn i18n_candidates(preferred_major: Option<u8>) -> Vec<String> {
    let stem = if cfg!(target_os = "windows") {
        "icuin"
    } else {
        "icui18n"
    };
    library_candidates(stem, preferred_major)
}

fn library_candidates(stem: &str, preferred_major: Option<u8>) -> Vec<String> {
    let majors = preferred_major
        .into_iter()
        .chain((40..=100).rev())
        .collect::<Vec<_>>();

    if cfg!(target_os = "windows") {
        let mut result = majors
            .into_iter()
            .map(|major| format!("{stem}{major}.dll"))
            .collect::<Vec<_>>();
        result.push(format!("{stem}.dll"));
        result
    } else if cfg!(target_os = "macos") {
        let mut result = vec![format!("lib{stem}.dylib")];
        result.extend(
            majors
                .into_iter()
                .map(|major| format!("lib{stem}.{major}.dylib")),
        );
        if stem == "icuuc" {
            result.push("/usr/lib/libicucore.A.dylib".to_owned());
        }
        result
    } else {
        let mut result = vec![format!("lib{stem}.so")];
        result.extend(
            majors
                .into_iter()
                .map(|major| format!("lib{stem}.so.{major}")),
        );
        result
    }
}
