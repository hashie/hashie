# frozen_string_literal: true

require 'yard'
# Run YARD's generic DSL documentation handler before the more specific Dash handler.
require 'yard/handlers/ruby/dsl_handler'
require_relative 'yard/dash_property_handler'
