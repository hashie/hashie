source 'http://rubygems.org'

gemspec

group :development do
  gem 'pry'
  gem 'pry-stack_explorer', platforms: [:ruby_19, :ruby_20, :ruby_21]
  gem 'rubocop', '0.28.0'
  gem 'guard', '~> 2.6.1'
  gem 'guard-rspec', '~> 4.3.1', require: false
end

group :test do
  # ActiveSupport required to test compatibility with ActiveSupport Core Extensions.
  gem 'activesupport', require: false
  gem 'codeclimate-test-reporter', require: false
  gem 'rspec-core', '~> 3.1.7'
end
