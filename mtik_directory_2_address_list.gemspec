# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mtik_directory_2_address_list/version'

Gem::Specification.new do |spec|
  spec.name          = 'mtik_directory_2_address_list'
  spec.version       = MtikDirectory2AddressList::VERSION
  spec.authors       = ['Andre Luiz dos Santos']
  spec.email         = ['andre.netvision.com.br@gmail.com']
  spec.summary       = %q{Synchronize a directory with a Mikrotik address list}

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest', '~> 5.5'
  spec.add_development_dependency 'mocha', '~> 1.1'
  spec.add_development_dependency 'simplecov', '~> 0.9'

  spec.add_runtime_dependency 'mtik', '~> 4.0'
end
