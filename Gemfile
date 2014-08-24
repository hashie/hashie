source 'http://rubygems.org'

platforms :rbx do
  gem 'rubysl'
  gem 'rubinius-developer_tools'
  gem 'racc'
end

group :development do
  gem 'pry'
  gem 'pry-stack_explorer', platforms: [:ruby_19, :ruby_20, :ruby_21]
  gem 'rubocop', '~> 0.25'
  gem 'guard', '~> 2.6.1'
  gem 'guard-rspec', '~> 4.3.1', require: false
end

gemspec

group :test do
  # ActiveSupport required to test compatibility with ActiveSupport Core Extensions.
  gem 'activesupport', require: false
end
