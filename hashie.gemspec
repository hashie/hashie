require File.expand_path('../lib/hashie/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Michael Bleigh", "Jerry Cheung"]
  gem.email         = ["michael@intridea.com", "jollyjerry@gmail.com"]
  gem.description   = %q{Hashie is a small collection of tools that make hashes more powerful. Currently includes Mash (Mocking Hash) and Dash (Discrete Hash).}
  gem.summary       = %q{Your friendly neighborhood hash toolkit.}
  gem.homepage      = 'https://github.com/intridea/hashie'

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "hashie"
  gem.require_paths = ['lib']
  gem.version       = Hashie::VERSION
  gem.license       = "MIT"

  gem.add_development_dependency 'rake', '~> 0.9.2'
  gem.add_development_dependency 'rspec', '~> 2.5'
  gem.add_development_dependency 'guard'
  gem.add_development_dependency 'guard-rspec'
  gem.add_development_dependency 'growl'
end
