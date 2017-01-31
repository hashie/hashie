ENV['RACK_ENV'] = 'test'

require 'rspec/core'
require 'rack/test'
require 'sinatra'
require 'omniauth'

class MyApplication < Sinatra::Base
  use Rack::Session::Cookie
  use OmniAuth::Strategies::Developer

  get '/' do
    'Hello World'
  end
end

module RSpecMixin
  include Rack::Test::Methods
  def app
    MyApplication
  end
end

RSpec.configure do |config|
  config.include RSpecMixin
  config.expect_with :rspec do |expect|
    expect.syntax = :expect
  end
end

describe 'omniauth' do
  it 'works' do
    get '/'
    expect(last_response).to be_ok
    expect(last_response.body).to eq 'Hello World'
  end
end
