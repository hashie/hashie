source 'http://rubygems.org'

gemspec

group :development do
  gem 'pry'
  gem 'pry-stack_explorer', platforms: [:ruby_19, :ruby_20, :ruby_21]
  gem 'rubocop', '0.34.2'
  gem 'guard', '~> 2.6.1'
  gem 'guard-rspec', '~> 4.3.1', require: false
end

group :test do
  # ActiveSupport required to test compatibility with ActiveSupport Core Extensions.
  if RUBY_VERSION >= '2.2.2'
    gem 'activesupport', '~> 5.x', require: false
    gem 'activemodel', '~> 5.x', require: false
  else
    gem 'activesupport', '~> 4.x', require: false
  end
  if RUBY_VERSION >= '2.1.0'
    gem 'dry-types', require: false
  else
    gem 'dry-monads', '0.1.1', require: false
    gem 'dry-types', '0.8.1', require: false
  end
  gem 'codeclimate-test-reporter', require: false
  gem 'rspec-core', '~> 3.1.7'
  gem 'danger-changelog', '~> 0.1.0', require: false
end
