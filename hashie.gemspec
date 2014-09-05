require File.expand_path('../lib/hashie/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = 'hashie'
  gem.version       = Hashie::VERSION
  gem.authors       = ['Michael Bleigh', 'Jerry Cheung']
  gem.email         = ['michael@intridea.com', 'jollyjerry@gmail.com']
  gem.description   = 'Hashie is a collection of classes and mixins that make hashes more powerful.'
  gem.summary       = 'Your friendly neighborhood hash library.'
  gem.homepage      = 'https://github.com/intridea/hashie'
  gem.license       = 'MIT'

  gem.require_paths = ['lib']
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec', '~> 3.0'
end
