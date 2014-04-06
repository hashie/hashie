require File.expand_path('../lib/hashie/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Michael Bleigh", "Jerry Cheung"]
  gem.email         = ["michael@intridea.com", "jollyjerry@gmail.com"]
  gem.description   = %q{Hashie is a collection of classes and mixins that make hashes more powerful.}
  gem.summary       = %q{Your friendly neighborhood hash library.}
  gem.homepage      = 'https://github.com/intridea/hashie'

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "hashie"
  gem.require_paths = ['lib']
  gem.version       = Hashie::VERSION
  gem.license       = "MIT"

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
end
