# frozen_string_literal: true

# Start with a clean base rather than inheriting root development dependencies.
@gemfile = ::Appraisal::Gemfile.new # rubocop:disable Style/RedundantConstantBase
gemfile.source 'https://rubygems.org'
gemfile.gemspec
gemfile.gem 'rake'
gemfile.gem 'rspec', '~> 3'

appraise 'active_support' do
  gem 'activesupport', '~> 5.x'
end

appraise 'coercion' do
  gem 'activemodel', '~> 6.1.0'
  gem 'dry-types', '>= 1.7', '< 2'
end

appraise 'elasticsearch' do
  gem 'elasticsearch-api', '~> 7.0.0'
  gem 'elasticsearch-model', '~> 7.0.0'
end

appraise 'omniauth-oauth2' do
  gem 'omniauth'
  gem 'omniauth-oauth2', '~> 1.4.0'
  gem 'rails', '~> 6.1.0'
  gem 'rspec-rails'
end

appraise 'omniauth' do
  gem 'benchmark-ips'
  gem 'omniauth'
  gem 'rack-test', '~> 0.6.3'
  gem 'sinatra'
end

appraise 'rails_7' do
  gem 'rails', '~> 7.0.0'
  gem 'rspec-rails'
  gem 'yard', '~> 0.9.45'
end

appraise 'rails-without-dependency' do
  # Only the shared Hashie and test dependencies are needed.
end

appraise 'rails' do
  gem 'rails', '~> 6.1.0'
  gem 'rspec-rails'
end
