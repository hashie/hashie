source 'http://rubygems.org'

gemspec

group :development do
  gem 'benchmark-ips'
  gem 'benchmark-memory'
  gem 'guard', '~> 2.6.1'
  gem 'guard-rspec', '~> 4.3.1', require: false
  gem 'guard-yield', '~> 0.1.0', require: false
  gem 'mutex_m'
  gem 'pry'
  gem 'rubocop', '1.82.0'

  group :test do
    # ActiveSupport required to test compatibility with ActiveSupport Core Extensions.
    gem 'activesupport', '~> 5.x', require: false
    gem 'rake'
    gem 'rspec', '~> 3'
    gem 'rspec-pending_for', '~> 0.1'
  end
end

group :test do
  gem 'danger-changelog', require: false
  gem 'danger-pr-comment', require: false
  gem 'danger-toc', require: false
  gem 'simplecov'
end
