#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

if ! ruby -e 'require "benchmark/memory"; require "twitter_cldr"' 2>/dev/null; then
  echo 'benchmark-memory and twitter_cldr are required: bundle install' >&2
  exit 1
fi

rake compile
mkdir -p benchmark/results

printf '\n=== YJIT disabled ===\n'
ruby --disable-yjit benchmark/formatters.rb \
  | tee benchmark/results/yjit-disabled.txt

printf '\n=== YJIT enabled ===\n'
ruby --yjit benchmark/formatters.rb \
  | tee benchmark/results/yjit-enabled.txt
