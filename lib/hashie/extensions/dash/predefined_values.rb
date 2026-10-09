module Hashie
  module Extensions
    module Dash
      # Extends a Dash with the ability to accept only predefined values on a property.
      #
      # == Example
      #
      #   class PersonHash < Hashie::Dash
      #     include Hashie::Extensions::Dash::PredefinedValues
      #
      #     property :gender, values: [:male, :female, :prefer_not_to_say]
      #     property :age, values: (0..150) # a Range
      #   end
      #
      #   person = PersonHash.new(gender: :male, age: -1)
      #   # => ArgumentError: The value '-1' is not accepted for property 'age'
      module PredefinedValues
        def self.included(base)
          base.instance_variable_set(:@values_for_properties, {})
          base.extend(ClassMethods)
          base.include(InstanceMethods)
        end

        module ClassMethods
          attr_reader :values_for_properties

          def inherited(klass)
            super
            klass.instance_variable_set(:@values_for_properties, values_for_properties.dup)
          end

          def property(property_name, options = {})
            super

            return unless (predefined_values = options[:values])

            assert_predefined_values!(predefined_values)
            set_predefined_values(property_name, predefined_values)
          end

          private

          def assert_predefined_values!(predefined_values)
            return if supported_type?(predefined_values)

            raise ArgumentError, %(`values` accepts an `Array` or a `Range`)
          end

          def supported_type?(predefined_values)
            [::Array, ::Range].any? { |klass| predefined_values.is_a?(klass) }
          end

          def set_predefined_values(property_name, predefined_values)
            @values_for_properties[property_name] = predefined_values
          end
        end

        module InstanceMethods
          def initialize(*)
            super

            assert_property_values!
          end

          private

          def assert_property_values!
            self.class.values_for_properties.each_key do |property|
              value = send(property)

              allowed_values = values_for_properties(property)
              if value && !allowed_values.include?(value)
                fail_property_value_error!(property, value, allowed_values)
              end
            end
          end

          def fail_property_value_error!(property, value, allowed_values)
            if allowed_values.is_a?(::Range)
              raise ArgumentError,
                    "value `#{value.inspect}` is not allowed for `#{property}`; " \
                    "expected a value in `#{allowed_values}`"
            end

            raise ArgumentError,
                  "value `#{value.inspect}` is not allowed for `#{property}`; " \
                  "expected one of `#{allowed_values.inspect}`"
          end

          def values_for_properties(property)
            self.class.values_for_properties[property]
          end
        end
      end
    end
  end
end
