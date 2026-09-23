use crate::bindings::*;
use libloading::Library;
use std::{env, ffi::CStr, sync::Arc};
use thiserror::Error;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SymbolVersion {
    /// ICU exports stable, unsuffixed names (for example Apple's libicucore).
    Unversioned,
    /// ICU's standard symbol renaming is enabled (for example `ucal_open_78`).
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
pub struct IcuVersion {
    pub major: u8,
    pub minor: u8,
    pub milli: u8,
    pub micro: u8,
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

#[derive(Debug, Error)]
pub enum Error {
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
    #[error("string contains an interior NUL byte")]
    InteriorNul,
}

#[derive(Clone)]
pub(crate) struct Icu {
    inner: Arc<Inner>,
}

pub(crate) struct Inner {
    // Libraries must outlive every copied function pointer below.
    _uc: Library,
    _i18n: Option<Library>,
    pub version: IcuVersion,
    pub symbol_version: SymbolVersion,
    pub u_error_name: UErrorName,
    pub ucal_open: UcalOpen,
    pub ucal_close: UcalClose,
    pub ucal_set_millis: UcalSetMillis,
    pub ucal_get_millis: UcalGetMillis,
    pub ucal_set_date: UcalSetDate,
    pub ucal_set_date_time: UcalSetDateTime,
    pub ucal_get: UcalGet,
    pub ucal_in_daylight_time: UcalInDaylightTime,
}

impl Icu {
    pub(crate) fn load() -> Result<Self, Error> {
        let (uc, _) = load_library("common", "OFFI_ICU_UC_LIB", common_candidates(None))?;
        let (symbol_version, get_version) = find_version_function(&uc)?;

        let mut raw_version: UVersionInfo = [0; 4];
        unsafe { get_version(raw_version.as_mut_ptr()) };
        let version = IcuVersion {
            major: raw_version[0],
            minor: raw_version[1],
            milli: raw_version[2],
            micro: raw_version[3],
        };

        let u_error_name = unsafe { resolve::<UErrorName>(&uc, symbol_version, "u_errorName")? };

        // Apple's libicucore combines common and i18n APIs. Try it before
        // opening a second library.
        let calendar_library = if has_symbol(&uc, symbol_version, "ucal_open") {
            None
        } else {
            let (library, _) = load_library(
                "internationalization",
                "OFFI_ICU_I18N_LIB",
                i18n_candidates(Some(version.major)),
            )?;
            Some(library)
        };
        let symbols = calendar_library.as_ref().unwrap_or(&uc);

        let inner = Inner {
            version,
            symbol_version,
            u_error_name,
            ucal_open: unsafe { resolve(symbols, symbol_version, "ucal_open")? },
            ucal_close: unsafe { resolve(symbols, symbol_version, "ucal_close")? },
            ucal_set_millis: unsafe { resolve(symbols, symbol_version, "ucal_setMillis")? },
            ucal_get_millis: unsafe { resolve(symbols, symbol_version, "ucal_getMillis")? },
            ucal_set_date: unsafe { resolve(symbols, symbol_version, "ucal_setDate")? },
            ucal_set_date_time: unsafe { resolve(symbols, symbol_version, "ucal_setDateTime")? },
            ucal_get: unsafe { resolve(symbols, symbol_version, "ucal_get")? },
            ucal_in_daylight_time: unsafe {
                resolve(symbols, symbol_version, "ucal_inDaylightTime")?
            },
            _uc: uc,
            _i18n: calendar_library,
        };

        Ok(Self {
            inner: Arc::new(inner),
        })
    }

    pub(crate) fn version(&self) -> IcuVersion {
        self.inner.version
    }

    pub(crate) fn symbol_version(&self) -> SymbolVersion {
        self.inner.symbol_version
    }

    pub(crate) fn functions(&self) -> &Inner {
        &self.inner
    }

    pub(crate) fn check_status(&self, status: UErrorCode) -> Result<(), Error> {
        if status.0 <= 0 {
            return Ok(());
        }
        let name = unsafe {
            let pointer = (self.inner.u_error_name)(status);
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
) -> Result<(Library, String), Error> {
    let names = env::var(override_variable)
        .ok()
        .map(|name| vec![name])
        .unwrap_or(candidates);
    let mut last_error = "no candidate names".to_owned();

    for name in &names {
        match unsafe { Library::new(name) } {
            Ok(library) => return Ok((library, name.clone())),
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
