require File.expand_path("../lib/ffi-icu/version", __FILE__)

Gem::Specification.new do |s|
  s.name                      = %q{ffi-icu}
  s.version                   = ICU::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors                   = ["Jari Bakken"]
  s.date                      = %q{2019-10-15}
  s.licenses                  = ['MIT']
  s.description               = %q{Provides charset detection, locale sensitive collation and more. Depends on libicu.}
  s.email                     = %q{jari.bakken@gmail.com}
  s.extra_rdoc_files          = ["LICENSE", "README.md"]
  s.files                     = `git ls-files`.split("\n")
  s.test_files                = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables               = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths             = ["lib"]

  s.homepage                  = %q{http://github.com/jarib/ffi-icu}
  s.rdoc_options              = ["--charset=UTF-8"]
  s.summary                   = %q{Simple Ruby FFI wrappers for things I need from ICU.}

  s.add_runtime_dependency "ffi", "~> 1.0", ">= 1.0.9"
  s.add_development_dependency 'rspec', '~> 3.9'
  s.add_development_dependency "rake", [">= 12.3.3"]
end
