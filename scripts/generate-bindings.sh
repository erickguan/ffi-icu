#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
header="${repo_root}/wrapper.h"
include_dir="${repo_root}/vendor/icu/include"
output="${repo_root}/src/bindings/generated.rs"

if ! command -v bindgen >/dev/null 2>&1; then
  echo 'bindgen CLI is required for regeneration: cargo install bindgen-cli' >&2
  exit 1
fi

bindgen "${header}" \
  --allowlist-type 'UBool' \
  --allowlist-type 'UChar' \
  --allowlist-type 'UDate' \
  --allowlist-type 'UErrorCode' \
  --allowlist-type 'UVersionInfo' \
  --allowlist-type 'UCalendar.*' \
  --allowlist-type 'UNumberFormat.*' \
  --allowlist-function '^$' \
  --default-enum-style newtype \
  --no-layout-tests \
  --no-doc-comments \
  --with-derive-default \
  --with-derive-hash \
  --with-derive-partialeq \
  --with-derive-eq \
  --with-derive-partialord \
  --with-derive-ord \
  --formatter rustfmt \
  --output "${output}" \
  -- \
  -DU_DISABLE_RENAMING=1 \
  -I"${include_dir}"

printf 'Generated %s from vendored ICU %s headers\n' \
  "${output}" "$(cat "${repo_root}/vendor/icu/VERSION")"
