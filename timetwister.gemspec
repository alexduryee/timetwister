# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'timetwister/version'

Gem::Specification.new do |spec|
  spec.name          = "timetwister"
  spec.version       = Timetwister::VERSION
  spec.authors       = ["Alex Duryee"]
  spec.email         = ["alexanderduryee@nypl.org"]
  spec.summary       = "Chronic wrapper to handle common date formats"
  spec.homepage      = "http://github.com/alexduryee/timetwister"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables  << 'timetwister'
  # spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_runtime_dependency "chronic", "~> 0.10.2"
end
