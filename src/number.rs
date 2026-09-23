use crate::{
    bindings::{UErrorCode, UNumberFormat, UNumberFormatStyle},
    icu::{Error, Icu},
};
use std::{ffi::CString, ptr};

pub(crate) struct NumberFormatter {
    rep: *mut UNumberFormat,
    icu: Icu,
}

unsafe impl Send for NumberFormatter {}

impl Drop for NumberFormatter {
    fn drop(&mut self) {
        if !self.rep.is_null() {
            unsafe { (self.icu.functions().unum_close)(self.rep) };
        }
    }
}

impl NumberFormatter {
    pub(crate) fn decimal(locale: &str) -> Result<Self, Error> {
        Self::open(locale, UNumberFormatStyle::UNUM_DECIMAL)
    }

    pub(crate) fn currency(locale: &str, style: CurrencyStyle) -> Result<Self, Error> {
        Self::open(locale, style.into_raw())
    }

    fn open(locale: &str, style: UNumberFormatStyle) -> Result<Self, Error> {
        let icu = Icu::load()?;
        let locale = CString::new(locale).map_err(|_| Error::InteriorNul)?;
        let mut status = UErrorCode::U_ZERO_ERROR;
        let rep = unsafe {
            (icu.functions().unum_open)(
                style,
                ptr::null(),
                0,
                locale.as_ptr(),
                ptr::null_mut(),
                &mut status,
            )
        };
        icu.check_status(status)?;
        if rep.is_null() {
            return Err(Error::NullNumberFormatter);
        }
        Ok(Self { rep, icu })
    }

    pub(crate) fn format(&self, number: f64) -> Result<String, Error> {
        self.format_uchar(|buffer, capacity, status| unsafe {
            (self.icu.functions().unum_format_double)(
                self.rep,
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
            (self.icu.functions().unum_format_double_currency)(
                self.rep,
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
pub(crate) enum CurrencyStyle {
    Standard,
    Iso,
    Plural,
}

impl CurrencyStyle {
    pub(crate) fn from_name(name: &str) -> Option<Self> {
        Some(match name {
            "standard" | "default" => Self::Standard,
            "iso" => Self::Iso,
            "plural" => Self::Plural,
            _ => return None,
        })
    }

    fn into_raw(self) -> UNumberFormatStyle {
        match self {
            Self::Standard => UNumberFormatStyle::UNUM_CURRENCY,
            Self::Iso => UNumberFormatStyle::UNUM_CURRENCY_ISO,
            Self::Plural => UNumberFormatStyle::UNUM_CURRENCY_PLURAL,
        }
    }
}
