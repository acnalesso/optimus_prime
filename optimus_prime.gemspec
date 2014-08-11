# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'optimus_prime/version'

Gem::Specification.new do |spec|
  spec.name          = "optimus_prime"
  spec.version       = OptimusPrime::VERSION.dup
  spec.authors       = ["Antonio Nalesso"]
  spec.email         = ["acnalesso@yahoo.co.uk"]
  spec.summary       = %q{ Create endpoints and persists data }
  spec.description   = %q{ It allows developers to define endpoint, persist some data to be returned when called the endpoint defined.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"

  spec.add_dependency "thin"
  spec.add_dependency "faraday"
end
