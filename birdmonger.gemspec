
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'birdmonger/version'

Gem::Specification.new do |spec|
  spec.name          = 'birdmonger'
  spec.version       = Birdmonger::VERSION
  spec.authors       = ['Iikka Niinivaara']
  spec.email         = ['mebe@habeeb.it']

  spec.summary       = 'TwitterServer-based Rack handler'
  spec.description   = 'TwitterServer-based Rack handler'
  spec.homepage      = "TODO: Put your gem's website or public repo URL here."

  spec.platform      = 'java'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) } << 'lib/birdmonger.jar'
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rspec', '3.7.0'

  spec.add_runtime_dependency 'rack', '>= 1.6.4', '< 2.1'
end
