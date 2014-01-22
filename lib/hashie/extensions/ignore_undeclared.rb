module Hashie
  module Extensions
    # IgnoreUndeclared is a simple mixin that silently ignores
    # undeclared properties on initialization instead of
    # raising an error. This is useful when using a Trash to
    # capture a subset of a larger hash.
    #
    # Note that attempting to retrieve an undeclared property
    # will still raise a NoMethodError, even if a value for
    # that property was provided at initialization.
    #
    # @example
    #   class Person < Trash
    #     include Hashie::Extensions::IgnoreUndeclared
    #
    #     property :first_name
    #     property :last_name
    #   end
    #
    #   user_data = {
    #      :first_name => 'Freddy',
    #      :last_name => 'Nostrils',
    #      :email => 'freddy@example.com'
    #   }
    #
    #   p = Person.new(user_data) # 'email' is silently ignored
    #
    #   p.first_name # => 'Freddy'
    #   p.last_name  # => 'Nostrils'
    #   p.email      # => NoMethodError
    module IgnoreUndeclared
      def initialize_attributes(attributes)
        attributes.each_pair do |att, value|
          if self.class.property?(att) || (self.class.respond_to?(:translations) && self.class.translations.include?(att.to_sym))
            self[att] = value
          end
        end if attributes
      end
    end
  end
end
