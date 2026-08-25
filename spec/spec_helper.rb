if ENV['CI']
  require 'simplecov'
  require 'simplecov-lcov'

  SimpleCov::Formatter::LcovFormatter.config.report_with_single_file = true
  SimpleCov::Formatter::LcovFormatter.config.single_report_path = 'coverage/lcov.info'
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
                                                                    SimpleCov::Formatter::HTMLFormatter,
                                                                    SimpleCov::Formatter::LcovFormatter
                                                                  ])
  SimpleCov.start do
    add_filter '/spec/support/'
  end
end

require 'pry'

require 'rspec'
require 'hashie'
require 'json'
require 'rspec/pending_for'
require './spec/support/ruby_version_check'
require './spec/support/logger'
require './spec/support/matchers'

Dir[File.expand_path(File.join(__dir__, 'support', '**', '*'))].sort.each { |file| require file }

RSpec.configure do |config|
  config.extend RubyVersionCheck
  config.expect_with :rspec do |expect|
    expect.syntax = :expect
  end
  config.warnings = true
end
