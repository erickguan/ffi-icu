use crate::{
    bindings::{UCalendar, UCalendarDateFields, UCalendarType, UErrorCode},
    icu::{Error, Icu},
};
use std::ffi::CString;

/// A small owned wrapper around ICU4C's `UCalendar`.
pub(crate) struct Calendar {
    rep: *mut UCalendar,
    icu: Icu,
}

unsafe impl Send for Calendar {}

impl Drop for Calendar {
    fn drop(&mut self) {
        if !self.rep.is_null() {
            unsafe { (self.icu.functions().ucal_close)(self.rep) };
        }
    }
}

impl Calendar {
    pub(crate) fn new(zone_id: &str, locale: &str) -> Result<Self, Error> {
        let icu = Icu::load()?;
        let zone_id = zone_id.encode_utf16().collect::<Vec<_>>();
        let locale = CString::new(locale).map_err(|_| Error::InteriorNul)?;
        let mut status = UErrorCode::U_ZERO_ERROR;

        let rep = unsafe {
            (icu.functions().ucal_open)(
                zone_id.as_ptr(),
                zone_id.len() as i32,
                locale.as_ptr(),
                UCalendarType::UCAL_GREGORIAN,
                &mut status,
            )
        };
        icu.check_status(status)?;
        if rep.is_null() {
            return Err(Error::NullCalendar);
        }

        Ok(Self { rep, icu })
    }

    pub(crate) fn icu_version(&self) -> String {
        self.icu.version().to_string()
    }

    pub(crate) fn symbol_version(&self) -> String {
        self.icu.symbol_version().to_string()
    }

    pub(crate) fn set_millis(&self, date_time: f64) -> Result<(), Error> {
        let mut status = UErrorCode::U_ZERO_ERROR;
        unsafe { (self.icu.functions().ucal_set_millis)(self.rep, date_time, &mut status) };
        self.icu.check_status(status)
    }

    pub(crate) fn millis(&self) -> Result<f64, Error> {
        let mut status = UErrorCode::U_ZERO_ERROR;
        let millis = unsafe { (self.icu.functions().ucal_get_millis)(self.rep, &mut status) };
        self.icu.check_status(status)?;
        Ok(millis)
    }

    /// Sets a local calendar date. `month` is zero-based, matching ICU.
    pub(crate) fn set_date(&self, year: i32, month: i32, day: i32) -> Result<(), Error> {
        let mut status = UErrorCode::U_ZERO_ERROR;
        unsafe { (self.icu.functions().ucal_set_date)(self.rep, year, month, day, &mut status) };
        self.icu.check_status(status)
    }

    /// Sets local calendar date/time. `month` is zero-based, matching ICU.
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
            (self.icu.functions().ucal_set_date_time)(
                self.rep,
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
        let value =
            unsafe { (self.icu.functions().ucal_get)(self.rep, field.into_raw(), &mut status) };
        self.icu.check_status(status)?;
        Ok(value)
    }

    pub(crate) fn zone_offset(&self) -> Result<i32, Error> {
        self.field(CalendarField::ZoneOffset)
    }

    pub(crate) fn dst_offset(&self) -> Result<i32, Error> {
        self.field(CalendarField::DstOffset)
    }

    pub(crate) fn in_daylight_time(&self) -> Result<bool, Error> {
        let mut status = UErrorCode::U_ZERO_ERROR;
        let result = unsafe { (self.icu.functions().ucal_in_daylight_time)(self.rep, &mut status) };
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
    pub(crate) fn from_name(name: &str) -> Option<Self> {
        Some(match name {
            "era" => Self::Era,
            "year" => Self::Year,
            "month" => Self::Month,
            "day" | "day_of_month" => Self::DayOfMonth,
            "hour" | "hour_of_day" => Self::HourOfDay,
            "minute" => Self::Minute,
            "second" => Self::Second,
            "millisecond" => Self::Millisecond,
            "zone_offset" => Self::ZoneOffset,
            "dst_offset" => Self::DstOffset,
            _ => return None,
        })
    }

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
