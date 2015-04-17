# coding: utf-8

Gem::Specification.new do |spec|
  spec.name        = 'tempest'
  spec.version     = '0.0.1'
  spec.platform    = Gem::Platform::RUBY
  spec.authors     = ['David Baggerman']
  spec.email       = ['david.baggerman@fairfaxmedia.com.au']
  spec.homepage    = 'https://github.com/fairfaxmedia/tempest'
  spec.summary     = %(Ruby DSL for generating CloudFormation templates)
  spec.description = %(WIP)
  spec.licenses    = ['Apache License, Version 2.0']

  spec.files         = `git ls-files`.split("\n")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'json', '~> 1.7', '< 2.0'
end
