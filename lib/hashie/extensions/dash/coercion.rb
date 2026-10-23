# frozen_string_literal: true

module Hashie
  module Extensions
    module Dash
      # Adds per-property coercion to a Dash.
      #
      # @example
      #   klass = Class.new(Hashie::Dash) do
      #     include Hashie::Extensions::Dash::Coercion
      #     property :count, coerce: Integer
      #   end
      #   klass.new(count: '3').count # => 3
      module Coercion
        # Extends a Dash with the ability to define coercion for properties.
        #
        # @example
        #   klass = Class.new(Hashie::Dash) do
        #     include Hashie::Extensions::Dash::Coercion
        #     property :count, coerce: Integer
        #   end
        #   klass.new(count: '3').count # => 3
        def self.included(base)
          base.send :include, Hashie::Extensions::Coercion
          base.extend ClassMethods
        end

        # Property declarations supporting coercion.
        #
        # @example
        #   klass = Class.new(Hashie::Dash) do
        #     include Hashie::Extensions::Dash::Coercion
        #     property :count, coerce: Integer
        #   end
        #   klass.new(count: '3').count # => 3
        module ClassMethods
          # Defines a property on the Dash. Options are the standard
          # `Hashie::Dash#property` options plus:
          #
          # * `:coerce` - The class into which you want the property coerced.
          #
          # @example
          #   klass = Class.new(Hashie::Dash) do
          #     include Hashie::Extensions::Dash::Coercion
          #     property :count, coerce: Integer
          #   end
          #   klass.new(count: '3').count # => 3
          def property(property_name, options = {})
            super
            coerce_key property_name, options[:coerce] if options[:coerce]
          end
        end
      end
    end
  end
end
