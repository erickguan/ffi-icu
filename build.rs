use std::{env, path::PathBuf};

fn main() {
    println!("cargo:rerun-if-changed=wrapper.h");
    println!("cargo:rerun-if-env-changed=ICU_INCLUDE_DIR");
    println!("cargo:rerun-if-env-changed=LIBCLANG_PATH");

    let mut builder = bindgen::Builder::default()
        .header("wrapper.h")
        // ICU normally rewrites declarations such as ucal_open to ucal_open_78.
        // Runtime symbol resolution handles that, so generated declarations should
        // describe the stable C API names and types only.
        .clang_arg("-DU_DISABLE_RENAMING=1")
        .allowlist_type("UBool")
        .allowlist_type("UChar")
        .allowlist_type("UDate")
        .allowlist_type("UErrorCode")
        .allowlist_type("UVersionInfo")
        .allowlist_type("UCalendar.*")
        .allowlist_function("^$")
        .default_enum_style(bindgen::EnumVariation::NewType {
            is_bitfield: false,
            is_global: false,
        })
        .derive_debug(true)
        .derive_default(true)
        .derive_copy(true)
        .derive_eq(true)
        .derive_hash(true)
        .derive_ord(true)
        .layout_tests(false)
        .generate_comments(true)
        .parse_callbacks(Box::new(bindgen::CargoCallbacks::new()));

    if let Some(include_dir) = env::var_os("ICU_INCLUDE_DIR") {
        builder = builder.clang_arg(format!("-I{}", PathBuf::from(include_dir).display()));
    } else if let Ok(icu) = pkg_config::Config::new()
        .cargo_metadata(false)
        .probe("icu-i18n")
    {
        for include_path in icu.include_paths {
            builder = builder.clang_arg(format!("-I{}", include_path.display()));
        }
    }

    let bindings = builder
        .generate()
        .expect("bindgen could not generate the ICU calendar bindings");
    let output = PathBuf::from(env::var_os("OUT_DIR").expect("OUT_DIR is set"))
        .join("icu_calendar_bindings.rs");
    bindings
        .write_to_file(output)
        .expect("could not write generated ICU calendar bindings");
}
