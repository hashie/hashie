# frozen_string_literal: true

module Hashie
  module Extensions
    module Dash
      # Extends a Dash with the ability to accept only predefined values on a property.
      #
      # @example
      #
      #   class PersonHash < Hashie::Dash
      #     include Hashie::Extensions::Dash::PredefinedValues
      #
      #     property :gender, values: [:male, :female, :prefer_not_to_say]
      #     property :age, values: (0..150) # a Range
      #   end
      #
      #   expect { PersonHash.new(gender: :male, age: -1) }
      #     .to raise_error(ArgumentError, /value `-1` is not allowed for `age`/)
      #   PersonHash.new(gender: :male, age: 42).age # => 42
      module PredefinedValues
        # @example Install predefined-value declarations
        #   klass = Class.new(Hashie::Dash) do
        #     include Hashie::Extensions::Dash::PredefinedValues
        #   end
        #   klass.values_for_properties # => {}
        def self.included(base)
          base.instance_variable_set(:@values_for_properties, {})
          base.extend(ClassMethods)
          base.include(InstanceMethods)
        end

        # Declares and inherits permitted values for properties.
        #
        # @example
        #   klass = Class.new(Hashie::Dash) do
        #     include Hashie::Extensions::Dash::PredefinedValues
        #     property :status, values: [:open, :closed]
        #   end
        #   klass.values_for_properties # => {status: [:open, :closed]}
        module ClassMethods
          # @example Read the constraints for declared properties
          #   klass = Class.new(Hashie::Dash) do
          #     include Hashie::Extensions::Dash::PredefinedValues
          #     property :age, values: (0..150)
          #   end
          #   klass.values_for_properties # => {age: (0..150)}
          attr_reader :values_for_properties

          # @example Inherit constraints without sharing the constraint map
          #   parent = Class.new(Hashie::Dash) do
          #     include Hashie::Extensions::Dash::PredefinedValues
          #     property :status, values: [:open, :closed]
          #   end
          #   child = Class.new(parent) { property :age, values: (0..150) }
          #   child.values_for_properties.keys # => [:status, :age]
          #   parent.values_for_properties.keys # => [:status]
          def inherited(klass)
            super
            klass.instance_variable_set(:@values_for_properties, values_for_properties.dup)
          end

          # @example Accept an array or range of values
          #   klass = Class.new(Hashie::Dash) do
          #     include Hashie::Extensions::Dash::PredefinedValues
          #     property :status, values: [:open, :closed]
          #     property :age, values: (0..150)
          #   end
          #   klass.new(status: :open, age: 42).age # => 42
          #   expect { klass.new(status: :unknown) }.to raise_error(ArgumentError, /status/)
          def property(property_name, options = {})
            super

            return unless (predefined_values = options[:values])

            _assert_predefined_values!(predefined_values)
            _set_predefined_values(property_name, predefined_values)
          end

          private

          def _assert_predefined_values!(predefined_values)
            return if _supported_type?(predefined_values)

            raise ArgumentError, %(`values` accepts an `Array` or a `Range`)
          end

          def _supported_type?(predefined_values)
            [::Array, ::Range].any? { |klass| predefined_values.is_a?(klass) }
          end

          def _set_predefined_values(property_name, predefined_values)
            @values_for_properties[property_name] = predefined_values
          end
        end

        # Validates property constraints when constructing a Dash.
        #
        # @example
        #   klass = Class.new(Hashie::Dash) do
        #     include Hashie::Extensions::Dash::PredefinedValues
        #     property :status, values: [:open, :closed]
        #   end
        #   klass.new(status: :open).status # => :open
        module InstanceMethods
          # @example Reject values outside the declared set
          #   klass = Class.new(Hashie::Dash) do
          #     include Hashie::Extensions::Dash::PredefinedValues
          #     property :status, values: [:open, :closed]
          #   end
          #   expect { klass.new(status: :unknown) }.to raise_error(ArgumentError, /status/)
          #   klass.new.status # => nil
          def initialize(*)
            super

            _assert_property_values!
          end

          private

          def _assert_property_values!
            self.class.values_for_properties.each_key do |property|
              value = self[property]

              allowed_values = self.class.values_for_properties[property]
              _fail_property_value_error!(property, value, allowed_values) if value && !allowed_values.include?(value)
            end
          end

          def _fail_property_value_error!(property, value, allowed_values)
            expected_values = if allowed_values.is_a?(::Range)
                                "a value in `#{allowed_values}`"
                              else
                                "one of `#{allowed_values.inspect}`"
                              end

            raise ArgumentError,
                  "value `#{value.inspect}` is not allowed for `#{property}`; " \
                  "expected #{expected_values}"
          end
        end
      end
    end
  end
end
