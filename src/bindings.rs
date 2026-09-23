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
    include!(concat!(env!("OUT_DIR"), "/icu_calendar_bindings.rs"));
}

pub(crate) use generated::{
    UBool, UCalendar, UCalendarDateFields, UCalendarType, UChar, UDate, UErrorCode, UVersionInfo,
};

pub(crate) type UGetVersion = unsafe extern "C" fn(*mut u8);
pub(crate) type UErrorName = unsafe extern "C" fn(UErrorCode) -> *const c_char;

pub(crate) type UcalOpen = unsafe extern "C" fn(
    *const UChar,
    i32,
    *const c_char,
    UCalendarType,
    *mut UErrorCode,
) -> *mut UCalendar;
pub(crate) type UcalClose = unsafe extern "C" fn(*mut UCalendar);
pub(crate) type UcalSetMillis = unsafe extern "C" fn(*mut UCalendar, UDate, *mut UErrorCode);
pub(crate) type UcalGetMillis = unsafe extern "C" fn(*const UCalendar, *mut UErrorCode) -> UDate;
pub(crate) type UcalSetDate = unsafe extern "C" fn(*mut UCalendar, i32, i32, i32, *mut UErrorCode);
pub(crate) type UcalSetDateTime =
    unsafe extern "C" fn(*mut UCalendar, i32, i32, i32, i32, i32, i32, *mut UErrorCode);
pub(crate) type UcalGet =
    unsafe extern "C" fn(*const UCalendar, UCalendarDateFields, *mut UErrorCode) -> i32;
pub(crate) type UcalInDaylightTime =
    unsafe extern "C" fn(*const UCalendar, *mut UErrorCode) -> UBool;

// Assert the opaque handle remains pointer-shaped in generated bindings.
const _: fn(UCalendar) -> *mut c_void = |value| value;
