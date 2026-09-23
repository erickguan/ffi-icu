#!/usr/bin/env bash
set -euo pipefail

version="${ICU_VERSION:-78.2}"
archive="icu4c-${version}-sources.tgz"
url="https://github.com/unicode-org/icu/releases/download/release-${version}/${archive}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
destination="${repo_root}/vendor/icu"
tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

curl --fail --location --retry 3 "${url}" --output "${tmp}/${archive}"
tar -xzf "${tmp}/${archive}" -C "${tmp}"

rm -rf "${destination}/include"
mkdir -p "${destination}/include/unicode"
cp "${tmp}"/icu/source/common/unicode/*.h "${destination}/include/unicode/"
cp "${tmp}"/icu/source/i18n/unicode/*.h "${destination}/include/unicode/"
printf '%s\n' "${version}" > "${destination}/VERSION"

printf 'Vendored ICU %s headers in %s\n' "${version}" "${destination}"
