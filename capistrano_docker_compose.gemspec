lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'yaml'

Gem::Specification.new do |spec|
  spec.name          = 'capistrano_docker_compose'
  spec.version       = YAML.load_file('config/version.yml')[:current_version]
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

  spec.add_dependency 'capistrano', '>= 3.17'

  spec.add_development_dependency 'bundler', '~> 2.3.10'
  spec.add_development_dependency 'rake'
end
