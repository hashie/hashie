# frozen_string_literal: true

source 'http://rubygems.org'

gemspec

group :development do
  gem 'benchmark-ips'
  gem 'benchmark-memory'
  gem 'bundler'
  gem 'guard', '~> 2.6.1'
  gem 'guard-rspec', '~> 4.3.1', require: false
  gem 'guard-yield', '~> 0.1.0', require: false
  gem 'mutex_m'
  gem 'pry'
  gem 'rubocop', '1.91.0'
  gem 'rubocop-exception_messages' if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.2')
  gem 'rubocop-rake'
  gem 'rubocop-rspec'
  gem 'rubocop-spellcheck', '~> 0.2', require: false if RUBY_ENGINE == 'ruby' && Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.2')
  gem 'yard', '~> 0.9.45', require: false
end

group :test do
  # ActiveSupport required to test compatibility with ActiveSupport Core Extensions.
  gem 'activesupport', '~> 5.x', require: false
  gem 'danger-changelog', require: false
  gem 'danger-pr-comment', require: false
  gem 'danger-toc', require: false
  gem 'rake'
  gem 'rspec', '~> 3'
  gem 'rspec-pending_for', '~> 0.1'
  gem 'simplecov'
  gem 'simplecov-lcov', require: false
end
