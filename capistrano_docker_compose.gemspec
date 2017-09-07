lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'capistrano_docker_compose'
  spec.version       = '0.1.1'
  spec.authors       = ["Mike State"]
  spec.email         = ["mstate@gmail.com"]
  spec.description   = %q{Docker support for Capistrano 3.x}
  spec.summary       = %q{Docker support for Capistrano 3.x}
  spec.homepage      = 'https://github.com/mstate/capistrano_docker_compose'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'capistrano', '>= 3.4'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
end
