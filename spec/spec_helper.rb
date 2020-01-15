if ENV['CI']
  require 'simplecov'
  SimpleCov.start
end

require 'pry'

require 'rspec'
require 'hashie'
require 'rspec/pending_for'
require './spec/support/ruby_version_check'
require './spec/support/logger'
require './spec/support/matchers'

RSpec.configure do |config|
  config.extend RubyVersionCheck
  config.expect_with :rspec do |expect|
    expect.syntax = :expect
  end
  config.warnings = true
end
