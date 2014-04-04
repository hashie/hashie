require 'set'

module Hashie
  module Extensions
    # The Structure extension provides facilities for declaring
    # properties that a Hash can have. This provides for the
    # creation of structures that still behave like hashes but
    # do not allow setting non-allowed keys.
    #
    # @example
    #   class RestrictedHash < Hash
    #     include Hashie::Extensions::MergeInitializer
    #     include Hashie::Extensions::Structure
    #
    #     key :first
    #     key :second, :default => 'foo'
    #   end
    #
    #   h = RestrictedHash.new(:first => 1)
    #   h[:first]  # => 1
    #   h[:second] # => 'foo'
    #   h[:third]  # => ArgumentError
    #
    module Structure
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        attr_writer :permitted_keys, :default_values

        def permitted_keys
          @permitted_keys ||= Set.new
        end

        def default_values
          @default_values ||= {}
        end

        def key(key, options = {})
          permitted_keys << key

          if options[:default]
            default_values[key] = options.delete(:default)
          end

          permitted_keys
        end

        def inherited(klass)
          klass.class_eval do
            @permitted_keys = superclass.permitted_keys.dup
            @default_values = superclass.default_values.dup
          end
          super
        end
      end

      def initialize(*args, &block)
        super

        self.class.default_values.each do |key, value|
          unless has_key?(key)
            begin
              self[key] = value.dup
            rescue TypeError
              self[key] = value
            end
          end
        end
      end

      def [](key)
        assert_allowed_key!(key)
        super(key)
      end

      def []=(key, value)
        assert_allowed_key!(key)
        super(key, value)
      end

      def fetch(key, *args, &block)
        assert_allowed_key!(key)
        super(key, *args, &block)
      end

      def merge(other, &block)
        result = super
        result.keys.each {|key| assert_allowed_key!(key) }
        result
      end

      def merge!(other, &block)
        super
        keys.each {|key| assert_allowed_key!(key)  }
        self
      end

      protected

      def assert_allowed_key!(key)
        raise KeyError, "Key #{key.inspect} is not allowed for this hash" unless self.class.permitted_keys.include?(key)
      end
    end
  end
end
