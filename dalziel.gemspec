# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dalziel/version'

Gem::Specification.new do |spec|
  spec.name          = "dalziel"
  spec.version       = Dalziel::VERSION
  spec.authors       = ["iain"]
  spec.email         = ["iain@iain.nl"]

  spec.summary       = %q{Convenience gem for testing JSON API calls}
  spec.description   = %q{Convenience gem for testing JSON API calls}
  spec.homepage      = "https://github.com/iain/dalziel"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"

  spec.add_dependency "json_expressions", "~> 0.8"
  spec.add_dependency "webmock", "~> 3.0"
end
