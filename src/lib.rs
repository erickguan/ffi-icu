mod bindings;
mod calendar;
mod icu;
mod number;

use calendar::{Calendar as NativeCalendar, CalendarField};
use icu::Icu;
use magnus::{Error, Ruby, function, method, prelude::*};
use number::{CurrencyStyle, NumberFormatter as NativeNumberFormatter};

#[magnus::wrap(class = "ICU::Calendar", free_immediately)]
struct Calendar {
    native: NativeCalendar,
}

impl Calendar {
    fn new(zone_id: String, locale: String) -> Result<Self, Error> {
        Ok(Self {
            native: NativeCalendar::new(&zone_id, &locale).map_err(to_ruby_error)?,
        })
    }

    fn icu_version(&self) -> String {
        self.native.icu_version()
    }

    fn symbol_version(&self) -> String {
        self.native.symbol_version()
    }

    fn set_millis(&self, millis: f64) -> Result<(), Error> {
        self.native.set_millis(millis).map_err(to_ruby_error)
    }

    fn millis(&self) -> Result<f64, Error> {
        self.native.millis().map_err(to_ruby_error)
    }

    fn set_date(&self, year: i32, zero_based_month: i32, day: i32) -> Result<(), Error> {
        self.native
            .set_date(year, zero_based_month, day)
            .map_err(to_ruby_error)
    }

    fn set_date_time(
        &self,
        year: i32,
        zero_based_month: i32,
        day: i32,
        hour: i32,
        minute: i32,
        second: i32,
    ) -> Result<(), Error> {
        self.native
            .set_date_time(year, zero_based_month, day, hour, minute, second)
            .map_err(to_ruby_error)
    }

    fn field(&self, name: String) -> Result<i32, Error> {
        let field = CalendarField::from_name(&name).ok_or_else(|| {
            let ruby = Ruby::get().expect("Ruby API is available while handling a Ruby call");
            Error::new(
                ruby.exception_arg_error(),
                format!("unknown calendar field: {name}"),
            )
        })?;
        self.native.field(field).map_err(to_ruby_error)
    }

    fn zone_offset(&self) -> Result<i32, Error> {
        self.native.zone_offset().map_err(to_ruby_error)
    }

    fn dst_offset(&self) -> Result<i32, Error> {
        self.native.dst_offset().map_err(to_ruby_error)
    }

    fn in_daylight_time(&self) -> Result<bool, Error> {
        self.native.in_daylight_time().map_err(to_ruby_error)
    }
}

#[magnus::wrap(class = "ICU::NumberFormatter", free_immediately)]
struct NumberFormatter {
    native: NativeNumberFormatter,
}

impl NumberFormatter {
    fn new(locale: String) -> Result<Self, Error> {
        Ok(Self {
            native: NativeNumberFormatter::decimal(&locale).map_err(to_ruby_error)?,
        })
    }

    fn format(&self, number: f64) -> Result<String, Error> {
        self.native.format(number).map_err(to_ruby_error)
    }
}

#[magnus::wrap(class = "ICU::CurrencyFormatter", free_immediately)]
struct CurrencyFormatter {
    native: NativeNumberFormatter,
}

impl CurrencyFormatter {
    fn new(locale: String, style: String) -> Result<Self, Error> {
        let style = CurrencyStyle::from_name(&style).ok_or_else(|| {
            let ruby = Ruby::get().expect("Ruby API is available while handling a Ruby call");
            Error::new(
                ruby.exception_arg_error(),
                format!("unknown currency style: {style}"),
            )
        })?;
        Ok(Self {
            native: NativeNumberFormatter::currency(&locale, style).map_err(to_ruby_error)?,
        })
    }

    fn format(&self, number: f64, currency: String) -> Result<String, Error> {
        self.native
            .format_currency(number, &currency)
            .map_err(to_ruby_error)
    }
}

fn runtime_icu_version() -> Result<String, Error> {
    Icu::load()
        .map(|icu| icu.version().to_string())
        .map_err(to_ruby_error)
}

fn runtime_symbol_version() -> Result<String, Error> {
    Icu::load()
        .map(|icu| icu.symbol_version().to_string())
        .map_err(to_ruby_error)
}

fn to_ruby_error(error: icu::Error) -> Error {
    let ruby = Ruby::get().expect("Ruby API is available while handling a Ruby call");
    Error::new(ruby.exception_runtime_error(), error.to_string())
}

#[magnus::init(name = "offi_icu")]
fn init(ruby: &Ruby) -> Result<(), Error> {
    let icu = ruby.define_module("ICU")?;
    icu.define_singleton_method("version", function!(runtime_icu_version, 0))?;
    icu.define_singleton_method("symbol_version", function!(runtime_symbol_version, 0))?;

    let calendar = icu.define_class("Calendar", ruby.class_object())?;
    calendar.define_singleton_method("new", function!(Calendar::new, 2))?;
    calendar.define_method("icu_version", method!(Calendar::icu_version, 0))?;
    calendar.define_method("symbol_version", method!(Calendar::symbol_version, 0))?;
    calendar.define_method("set_millis", method!(Calendar::set_millis, 1))?;
    calendar.define_method("millis", method!(Calendar::millis, 0))?;
    calendar.define_method("set_date", method!(Calendar::set_date, 3))?;
    calendar.define_method("set_date_time", method!(Calendar::set_date_time, 6))?;
    calendar.define_method("field", method!(Calendar::field, 1))?;
    calendar.define_method("zone_offset", method!(Calendar::zone_offset, 0))?;
    calendar.define_method("dst_offset", method!(Calendar::dst_offset, 0))?;
    calendar.define_method("in_daylight_time?", method!(Calendar::in_daylight_time, 0))?;

    let number_formatter = icu.define_class("NumberFormatter", ruby.class_object())?;
    number_formatter.define_singleton_method("new", function!(NumberFormatter::new, 1))?;
    number_formatter.define_method("format", method!(NumberFormatter::format, 1))?;

    let currency_formatter = icu.define_class("CurrencyFormatter", ruby.class_object())?;
    currency_formatter.define_singleton_method("new", function!(CurrencyFormatter::new, 2))?;
    currency_formatter.define_method("format", method!(CurrencyFormatter::format, 2))?;

    Ok(())
}
