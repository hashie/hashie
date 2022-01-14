source 'http://rubygems.org'

gemspec

require File.expand_path('../lib/hashie/extensions/ruby_version', __FILE__)

group :development do
  gem 'benchmark-ips'
  gem 'benchmark-memory'
  gem 'guard', '~> 2.6.1'
  gem 'guard-rspec', '~> 4.3.1', require: false
  gem 'guard-yield', '~> 0.1.0', require: false
  gem 'pry'
  gem 'pry-stack_explorer', platforms: %i[ruby_19 ruby_20 ruby_21]

  gem 'rubocop', '~> 1.0'

  group :test do
    # ActiveSupport required to test compatibility with ActiveSupport Core Extensions.
    gem 'activesupport', '~> 5.x', require: false
    gem 'rake'
    gem 'rspec', '~> 3'
    gem 'rspec-pending_for', '~> 0.1'
  end
end

group :test do
  gem 'danger-changelog', '~> 0.6.1', require: false
  gem 'danger-toc', '~> 0.2.0', require: false
  gem 'simplecov'
end
