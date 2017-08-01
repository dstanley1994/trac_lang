# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'trac_lang/version'

Gem::Specification.new do |spec|
  spec.name          = "trac_lang"
  spec.version       = TracLang::VERSION
  spec.authors       = ["David Stanley"]
  spec.email         = ["dstanley1994@yahoo.com"]

  spec.summary       = %q{Ruby implementation of the TRAC computer language.}
  spec.description   = %q{TRAC is a macro language invented in the 1950s.}
  spec.homepage      = %q(https://github.com/dstanley1994/trac_lang)
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'http://mygemserver.com'
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.require_paths = ["lib"]
  spec.bindir        = "exe"
  spec.executables   = ['trac_lang']
  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.has_rdoc = true
  spec.rdoc_options << '--include' << 'lib/trac_lang'

  spec.add_runtime_dependency "highline", "~> 1.7", ">= 1.7.8"
  
  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "cucumber", '~> 2.4', '>= 2.4.0'
  spec.add_development_dependency "aruba", "~> 0.14.2"
end
