use crate::icu::{Error, IcuNumberFormatter, NumberFormatStyle};

pub(crate) struct NumberFormatter {
    handle: IcuNumberFormatter,
}

impl NumberFormatter {
    pub(crate) fn decimal(locale: &str) -> Result<Self, Error> {
        Ok(Self {
            handle: IcuNumberFormatter::open(locale, NumberFormatStyle::Decimal)?,
        })
    }

    pub(crate) fn currency(locale: &str, style: CurrencyStyle) -> Result<Self, Error> {
        Ok(Self {
            handle: IcuNumberFormatter::open(locale, style.into_icu_style())?,
        })
    }

    pub(crate) fn format(&self, number: f64) -> Result<String, Error> {
        self.handle.format(number)
    }

    pub(crate) fn format_currency(&self, number: f64, currency: &str) -> Result<String, Error> {
        self.handle.format_currency(number, currency)
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

    fn into_icu_style(self) -> NumberFormatStyle {
        match self {
            Self::Standard => NumberFormatStyle::Currency,
            Self::Iso => NumberFormatStyle::CurrencyIso,
            Self::Plural => NumberFormatStyle::CurrencyPlural,
        }
    }
}
