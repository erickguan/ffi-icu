# frozen_string_literal: true

require_relative 'lib/offi_icu/version'

Gem::Specification.new do |spec|
  spec.name = 'offi-icu'
  spec.version = OffiIcu::VERSION
  spec.authors = ['Erick Guan']
  spec.summary = 'Magnus proof-of-concept bindings for ICU4C.'
  spec.description = 'A calendar-only ICU4C binding that discovers and loads the installed ICU version at runtime.'
  spec.homepage = 'https://github.com/erickguan/offi-icu'
  spec.license = 'Apache-2.0'
  spec.required_ruby_version = '>= 3.2'
  spec.required_rubygems_version = '>= 3.3.11'

  spec.files = Dir[
    'Cargo.lock',
    'Cargo.toml',
    'wrapper.h',
    'ext/**/*',
    'lib/**/*.rb',
    'scripts/**/*',
    'src/**/*.rs',
    'vendor/icu/**/*',
    'README.md'
  ]
  spec.extensions = ['ext/offi_icu/extconf.rb']
  spec.require_paths = ['lib']

  spec.add_dependency 'rb_sys', '~> 0.9'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
