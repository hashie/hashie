module Hashie
  module Extensions
    module Mash
      # Extends a Mash with the ability to require specific keys to be
      # set (non-nil) when constructed, while still allowing arbitrary,
      # undeclared keys to be assigned - unlike Hashie::Dash, which
      # restricts assignment to only pre-declared properties.
      #
      # == Example
      #
      #   class PersonMash < Hashie::Mash
      #     include Hashie::Extensions::Mash::RequiredKeys
      #
      #     required_keys :name, :email
      #   end
      #
      #   PersonMash.new(email: 'bob@example.com')
      #   # => ArgumentError: The following keys are required: name
      #
      #   person = PersonMash.new(name: 'Bob', email: 'bob@example.com')
      #   person.age = 42 # arbitrary, undeclared keys are still allowed
      module RequiredKeys
        def self.included(base)
          base.instance_variable_set(:@required_keys, [])
          base.extend(ClassMethods)
          base.include(InstanceMethods)
        end

        module ClassMethods
          def inherited(klass)
            super
            klass.instance_variable_set(:@required_keys, required_keys.dup)
          end

          # With no arguments, returns the keys currently declared as
          # required. With one or more arguments, declares those keys
          # as required. Keys are stored and compared as strings, so
          # both symbol and string keys are accepted.
          def required_keys(*keys)
            return @required_keys if keys.empty?

            @required_keys |= keys.map(&:to_s)
          end
        end

        module InstanceMethods
          def initialize(*args, &block)
            super
            assert_required_keys_set!
          end

          private

          def assert_required_keys_set!
            missing_keys = self.class.required_keys.select { |key| self[key].nil? }
            return if missing_keys.empty?

            raise ArgumentError, "The following keys are required: #{missing_keys.join(', ')}"
          end
        end
      end
    end
  end
end
