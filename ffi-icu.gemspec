require_relative 'lib/ffi-icu/version'

Gem::Specification.new do |spec|
  spec.name        = 'ffi-icu'
  spec.version     = ICU::VERSION
  spec.platform    = Gem::Platform::RUBY # rely on FFI library, but being platform-independent

  spec.required_rubygems_version = Gem::Requirement.new('>= 2.5.0')
  spec.authors     = ['Jari Bakken']
  spec.licenses    = ['MIT']
  spec.summary     = 'Simple Ruby FFI wrappers for International Components for Unicode (ICU).'
  spec.description = 'Provides charset detection, locale sensitive collation and more. Depends on libicu.'
  spec.email       = 'jari.bakken@gmail.com'
  spec.homepage    = 'https://github.com/erickguan/ffi-icu'

  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/master/CHANGELOG.md"

  spec.files = Dir['lib/**/*.rb', 'Gemfile', 'ffi-icu.gemspec', 'Rakefile']
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.extra_rdoc_files = ['LICENSE', 'README.md']
  spec.rdoc_options = ['--charset=UTF-8']

  spec.required_ruby_version = '>= 3.0.0'

  spec.add_runtime_dependency('bigdecimal', '~> 3.1')
  spec.add_runtime_dependency('ffi', '~> 1.0', '>= 1.0.9')
  spec.add_runtime_dependency('stringio', '~> 3.0')

  spec.metadata['rubygems_mfa_required'] = 'true'
end
