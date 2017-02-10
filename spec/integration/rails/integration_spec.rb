ENV['RACK_ENV'] = 'test'

require 'rspec/core'
require 'rails'
require 'rails/all'
require 'action_view/testing/resolvers'

module RailsApp
  class Application < ::Rails::Application
    config.action_dispatch.show_exceptions            = false
    config.active_support.deprecation                 = :stderr
    config.eager_load                                 = false
    config.root                                       = __dir__
    config.secret_key_base                            = 'hashieintegrationtest'

    routes.append do
      get '/' => 'application#index'
    end

    config.assets.paths << File.join(__dir__, 'assets/javascripts')
    config.assets.debug = true
  end
end

LAYOUT = <<-HTML
<!DOCTYPE html>
<html>
<head>
  <title>TestApp</title>
  <%= stylesheet_link_tag    "application", :media => "all" %>
  <%= javascript_include_tag "application" %>
  <%= csrf_meta_tags %>
</head>
<body>
<%= yield %>
</body>
</html>
HTML

INDEX = <<-HTML
<h1>Hello, world!</h1>
HTML

class ApplicationController < ActionController::Base
  include Rails.application.routes.url_helpers

  layout 'application'

  self.view_paths = [ActionView::FixtureResolver.new(
    'layouts/application.html.erb'         => LAYOUT,
    'application/index.html.erb'           => INDEX
  )]

  def index
  end
end

# the order is important
# hashie must be loaded first to register the railtie
# then we can initialize
require 'hashie'
RailsApp::Application.initialize!

RSpec.describe 'the Hashie logger' do
  it 'is set to the Rails logger' do
    expect(Hashie.logger).to eq(Rails.logger)
  end
end
