use crate::icu::{Error, IcuCalendar};

pub(crate) use crate::icu::CalendarField;

pub(crate) struct Calendar {
    handle: IcuCalendar,
}

impl Calendar {
    pub(crate) fn new(zone_id: &str, locale: &str) -> Result<Self, Error> {
        Ok(Self {
            handle: IcuCalendar::open(zone_id, locale)?,
        })
    }

    pub(crate) fn icu_version(&self) -> String {
        self.handle.version()
    }

    pub(crate) fn symbol_version(&self) -> String {
        self.handle.symbol_version()
    }

    pub(crate) fn set_millis(&self, date_time: f64) -> Result<(), Error> {
        self.handle.set_millis(date_time)
    }

    pub(crate) fn millis(&self) -> Result<f64, Error> {
        self.handle.millis()
    }

    /// Sets a local calendar date. `month` is zero-based, matching ICU.
    pub(crate) fn set_date(&self, year: i32, month: i32, day: i32) -> Result<(), Error> {
        self.handle.set_date(year, month, day)
    }

    /// Sets a local calendar date/time. `month` is zero-based, matching ICU.
    pub(crate) fn set_date_time(
        &self,
        year: i32,
        month: i32,
        day: i32,
        hour: i32,
        minute: i32,
        second: i32,
    ) -> Result<(), Error> {
        self.handle
            .set_date_time(year, month, day, hour, minute, second)
    }

    pub(crate) fn field(&self, field: CalendarField) -> Result<i32, Error> {
        self.handle.field(field)
    }

    pub(crate) fn zone_offset(&self) -> Result<i32, Error> {
        self.field(CalendarField::ZoneOffset)
    }

    pub(crate) fn dst_offset(&self) -> Result<i32, Error> {
        self.field(CalendarField::DstOffset)
    }

    pub(crate) fn in_daylight_time(&self) -> Result<bool, Error> {
        self.handle.in_daylight_time()
    }
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
}
