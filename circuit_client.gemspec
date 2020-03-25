# Ensure we require the local version and not one we might have installed already
spec = Gem::Specification.new do |s| 
  s.name = 'circuit_client'
  s.version = '1.0.0'
  s.author = 'Markus Benning'
  s.email = 'ich@markusbenning.de'
  s.homepage = 'https://github.com/benningm/circuit_client'
  s.platform = Gem::Platform::RUBY
  s.summary = 'Simple client for circuit REST API'
  s.license = 'MIT'
  s.files = Dir.glob('lib/**/*.rb') + Dir.glob('bin/*') + Dir.glob('[A-Z]*') + Dir.glob('test/**/*')
  s.require_paths << 'lib'
  s.bindir = 'bin'
  s.executables << 'send-circuit'
  s.add_development_dependency('rake', '~> 12')
  s.add_development_dependency('rdoc', '~> 6')
  s.add_runtime_dependency('faraday', '~> 1')
end
