source 'http://rubygems.org'

platforms :rbx do
  gem 'rubysl'
  gem 'rubinius-developer_tools'
  gem 'racc'
end

group :development do
  gem 'pry'
  gem 'pry-stack_explorer', platforms: [:ruby_19, :ruby_20, :ruby_21]
end

gemspec

gem 'rubocop', '0.24.1'

# ActiveSupport required to test compatibility with ActiveSupport Core Extensions.
gem 'activesupport', require: false
