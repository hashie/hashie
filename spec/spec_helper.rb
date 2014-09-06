require 'pry'

require 'rspec'
require 'hashie'

RSpec.configure do |config|
  config.expect_with :rspec do |expect|
    expect.syntax = :expect
  end
end
