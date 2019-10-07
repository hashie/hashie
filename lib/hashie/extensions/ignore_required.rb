module Hashie
  module Extensions
    # IgnoreRequired is a simple mixin that silently ignores
    # required properties on initialization and assignment instead of
    # raising an error. This is useful when using a building an object
    # that will eventually be match a Dash but is temporarily incomplete.
    #
    # @example
    #   class Person < Hashie::Dash
    #
    #     property :first_name, required: true
    #     property :last_name, required: true
    #     property :email
    #   end
    #
    #   class PartialPerson < Person
    #     include Hashie::Extensions::IgnoreRequired
    #   end
    #
    #   user_data = {
    #      :first_name => 'Freddy',
    #   }
    #
    #   p = Person.new(user_data) # ArgumentError: The property 'last_name' is required for Person.
    #
    #   p = PartialPerson.new(user_data)
    #   p.last_name = 'Nostrils'
    #   p.first_name # => 'Freddy'
    #   p.first_name # => 'Nostrils'
    #   p.email      # => nil
    #   p.foo        # => NoMethodError
    module IgnoreRequired
      def assert_property_required!(_property, _value)
        # do nothing
      end

      def assert_property_set!(_property)
        # do nothing
      end
    end
  end
end
