if ENV['CI']
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start
end

require 'pry'

require 'rspec'
require 'hashie'
require 'rspec/pending_for'
require './spec/support/ruby_version_check'

RSpec.configure do |config|
  config.extend RubyVersionCheck
  config.expect_with :rspec do |expect|
    expect.syntax = :expect
  end
end
