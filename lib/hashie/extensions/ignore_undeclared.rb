# frozen_string_literal: true

module Hashie
  module Extensions
    # IgnoreUndeclared is a simple mixin that silently ignores
    # undeclared properties on initialization instead of
    # raising an error. This is useful when using a Trash to
    # capture a subset of a larger hash.
    #
    # Note that attempting to retrieve or set an undeclared property
    # will still raise a NoMethodError, even if a value for
    # that property was provided at initialization.
    #
    # @example
    #   class Person < Hashie::Trash
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
    #   expect { p.email }.to raise_error(NoMethodError)
    module IgnoreUndeclared
      # @example Initialize only declared attributes
      #   class Person < Hashie::Trash
      #     include Hashie::Extensions::IgnoreUndeclared
      #     property :name
      #   end
      #   person = Person.new
      #   person.initialize_attributes(name: 'Ada', email: 'ada@example.com')
      #   person.to_h # => { name: 'Ada' }
      def initialize_attributes(attributes)
        return unless attributes

        klass = self.class
        translations = (klass.respond_to?(:translations) && klass.translations) || []

        super(attributes.select { |attr, _| klass.property?(attr) || translations.include?(attr) })
      end

      # @example Check the declaration rather than the current value
      #   class Person < Hashie::Trash
      #     include Hashie::Extensions::IgnoreUndeclared
      #     property :name
      #   end
      #   person = Person.new
      #   person.property_exists?(:name) # => true
      #   person.property_exists?(:email) # => false
      def property_exists?(property)
        self.class.property?(property)
      end
    end
  end
end
