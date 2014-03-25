# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mesque/version'

Gem::Specification.new do |spec|
  spec.name          = "mesque"
  spec.version       = Mesque::VERSION
  spec.authors       = ["Carl Hörberg"]
  spec.email         = ["carl@cloudamqp.com"]
  spec.summary       = "Work queue library using RabbitMQ as backend, API compatible with Resque"
  spec.homepage      = "https://github.com/cloudamqp/mesque"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
end
