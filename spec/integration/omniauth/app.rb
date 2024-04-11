require 'sinatra'
require 'omniauth'
require 'securerandom'

class MyApplication < Sinatra::Base
  use Rack::Session::Cookie, secret: SecureRandom.hex(64)
  use OmniAuth::Strategies::Developer

  get '/' do
    'Hello World'
  end
end
