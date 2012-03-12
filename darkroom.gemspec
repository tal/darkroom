# -*- encoding: utf-8 -*-
require File.expand_path('../lib/darkroom/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Tal Atlas"]
  gem.email         = ["me@tal.by"]
  gem.description   = %q{Gem for processing images and uploading to S3}
  gem.summary       = %q{Gem for processing images and uploading to S3}
  gem.homepage      = ""

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "darkroom"
  gem.require_paths = ["lib"]
  gem.version       = Darkroom::VERSION

  gem.add_dependency("url")
  gem.add_dependency("aws-sdk")

  gem.add_development_dependency("rspec", ["~> 2.8.0"])
end
