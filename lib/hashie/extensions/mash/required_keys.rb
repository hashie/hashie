# frozen_string_literal: true

module Hashie
  module Extensions
    module Mash
      # Extends a Mash with the ability to require specific keys to be
      # set (non-nil) when constructed, while still allowing arbitrary,
      # undeclared keys to be assigned - unlike Hashie::Dash, which
      # restricts assignment to only pre-declared properties.
      #
      # @example
      #
      #   class PersonMash < Hashie::Mash
      #     include Hashie::Extensions::Mash::RequiredKeys
      #
      #     required_keys :name, :email
      #   end
      #
      #   expect { PersonMash.new(email: 'bob@example.com') }
      #     .to raise_error(ArgumentError, 'the following keys are required: `name`')
      #
      #   person = PersonMash.new(name: 'Bob', email: 'bob@example.com')
      #   person.age = 42 # arbitrary, undeclared keys are still allowed
      #   person.age # => 42
      module RequiredKeys
        # @example Install required-key declarations
        #   klass = Class.new(Hashie::Mash) do
        #     include Hashie::Extensions::Mash::RequiredKeys
        #   end
        #   klass.required_keys # => []
        def self.included(base)
          base.instance_variable_set(:@required_keys, [])
          base.extend(ClassMethods)
          base.include(InstanceMethods)
        end

        # Class-level required-key declarations inherited by subclasses.
        #
        # @example
        #   klass = Class.new(Hashie::Mash) do
        #     include Hashie::Extensions::Mash::RequiredKeys
        #     required_keys :name
        #   end
        #   klass.required_keys # => ['name']
        module ClassMethods
          # @example Copy required keys when subclassing
          #   parent = Class.new(Hashie::Mash) do
          #     include Hashie::Extensions::Mash::RequiredKeys
          #     required_keys :name
          #   end
          #   child = Class.new(parent)
          #   child.required_keys :email
          #   child.required_keys # => ['name', 'email']
          #   parent.required_keys # => ['name']
          def inherited(klass)
            super
            klass.instance_variable_set(:@required_keys, required_keys.dup)
          end

          # With no arguments, returns the keys currently declared as
          # required. With one or more arguments, declares those keys
          # as required. Keys are stored and compared as strings, so
          # both symbol and string keys are accepted.
          #
          # @example
          #   klass = Class.new(Hashie::Mash) do
          #     include Hashie::Extensions::Mash::RequiredKeys
          #     required_keys :name, 'email', :name
          #   end
          #   klass.required_keys # => ['name', 'email']
          def required_keys(*keys)
            return @required_keys if keys.empty?

            @required_keys |= keys.map(&:to_s)
          end
        end

        # Checks required values when constructing a Mash.
        #
        # @example
        #   klass = Class.new(Hashie::Mash) do
        #     include Hashie::Extensions::Mash::RequiredKeys
        #     required_keys :name
        #   end
        #   klass.new(name: 'Ada').name # => 'Ada'
        module InstanceMethods
          # @example Reject nil or missing required values
          #   klass = Class.new(Hashie::Mash) do
          #     include Hashie::Extensions::Mash::RequiredKeys
          #     required_keys :name
          #   end
          #   expect { klass.new(name: nil) }.to raise_error(ArgumentError, /name/)
          #   klass.new(name: 'Ada', age: 37).age # => 37
          def initialize(*args, &block)
            super
            _assert_required_keys_set!
          end

          private

          def _assert_required_keys_set!
            missing_keys = self.class.required_keys.select { |key| self[key].nil? }
            return if missing_keys.empty?

            raise ArgumentError, "the following keys are required: `#{missing_keys.join(', ')}`"
          end
        end
      end
    end
  end
end
