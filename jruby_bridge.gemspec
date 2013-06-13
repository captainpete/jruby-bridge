# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jruby_bridge/version'

Gem::Specification.new do |spec|
  spec.name          = "jruby_bridge"
  spec.version       = JrubyBridge::VERSION
  spec.authors       = ["mkfs", "Peter Hollows"]
  spec.email         = ["peter.hollows@gmail.com"]
  spec.description   = %q{jruby_bridge proxies chunks of ruby code through to JRuby DRB Server and fetches the results.}
  spec.summary       = spec.description
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
