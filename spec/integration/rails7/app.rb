require 'action_controller/railtie'
require 'action_view/railtie'
require 'action_view/testing/resolvers'
require 'rails/test_unit/railtie'

module RailsApp
  class Application < ::Rails::Application
    config.eager_load      = false
    config.secret_key_base = 'hashieintegrationtest'
  end
end

Bundler.require(:default, Rails.env)

RailsApp::Application.initialize!
