//! Unsafe ICU C ABI types and function pointer signatures.
//!
//! Bindgen's generated types are deliberately isolated in this module. The
//! generated `extern` functions are disabled because ICU is loaded at runtime.

#![allow(
    dead_code,
    non_camel_case_types,
    non_snake_case,
    non_upper_case_globals
)]

use std::ffi::{c_char, c_void};

mod generated {
    #![allow(
        dead_code,
        non_camel_case_types,
        non_snake_case,
        non_upper_case_globals
    )]
    include!("bindings/generated.rs");
}

pub(super) use generated::{
    UBool, UCalendar, UCalendarDateFields, UCalendarType, UChar, UDate, UErrorCode, UNumberFormat,
    UNumberFormatStyle, UVersionInfo,
};

pub(super) type UGetVersion = unsafe extern "C" fn(*mut u8);
pub(super) type UErrorName = unsafe extern "C" fn(UErrorCode) -> *const c_char;

pub(super) type UcalOpen = unsafe extern "C" fn(
    *const UChar,
    i32,
    *const c_char,
    UCalendarType,
    *mut UErrorCode,
) -> *mut UCalendar;
pub(super) type UcalClose = unsafe extern "C" fn(*mut UCalendar);
pub(super) type UcalSetMillis = unsafe extern "C" fn(*mut UCalendar, UDate, *mut UErrorCode);
pub(super) type UcalGetMillis = unsafe extern "C" fn(*const UCalendar, *mut UErrorCode) -> UDate;
pub(super) type UcalSetDate = unsafe extern "C" fn(*mut UCalendar, i32, i32, i32, *mut UErrorCode);
pub(super) type UcalSetDateTime =
    unsafe extern "C" fn(*mut UCalendar, i32, i32, i32, i32, i32, i32, *mut UErrorCode);
pub(super) type UcalGet =
    unsafe extern "C" fn(*const UCalendar, UCalendarDateFields, *mut UErrorCode) -> i32;
pub(super) type UcalInDaylightTime =
    unsafe extern "C" fn(*const UCalendar, *mut UErrorCode) -> UBool;

pub(super) type UnumOpen = unsafe extern "C" fn(
    UNumberFormatStyle,
    *const UChar,
    i32,
    *const c_char,
    *mut c_void,
    *mut UErrorCode,
) -> *mut UNumberFormat;
pub(super) type UnumClose = unsafe extern "C" fn(*mut UNumberFormat);
pub(super) type UnumFormatDouble = unsafe extern "C" fn(
    *const UNumberFormat,
    f64,
    *mut UChar,
    i32,
    *mut c_void,
    *mut UErrorCode,
) -> i32;
pub(super) type UnumFormatDoubleCurrency = unsafe extern "C" fn(
    *const UNumberFormat,
    f64,
    *mut UChar,
    *mut UChar,
    i32,
    *mut c_void,
    *mut UErrorCode,
) -> i32;

// Assert the opaque handles remain pointer-shaped in generated bindings.
const _: fn(UCalendar) -> *mut c_void = |value| value;
const _: fn(UNumberFormat) -> *mut c_void = |value| value;
