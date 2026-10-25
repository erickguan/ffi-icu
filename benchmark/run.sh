#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
export BUNDLE_GEMFILE="$PWD/Gemfile"

exec bundle exec ruby run.rb "$@"
