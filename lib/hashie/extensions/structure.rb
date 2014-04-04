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
    #     property :first
    #     property :second, default: 'foo'
    #   end
    #
    #   h = RestrictedHash.new(first: 1)
    #   h[:first]  # => 1
    #   h[:second] # => 'foo'
    #   h[:third]  # => KeyError
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

        def property(key, options = {})
          permitted_keys << key
          default_values[key] = options.delete(:default) if options[:default]
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
          unless key?(key)
            begin
              self[key] = value.dup
            rescue TypeError
              self[key] = value
            end
          end
        end
      end

      def [](key)
        assert_permitted_key!(key)
        super(key)
      end

      def []=(key, value)
        assert_permitted_key!(key)
        super(key, value)
      end

      def fetch(key, *args, &block)
        assert_permitted_key!(key)
        super(key, *args, &block)
      end

      def merge(other, &block)
        result = super
        result.assert_permitted_keys!
        result
      end

      def merge!(other, &block)
        super
        assert_permitted_keys!
        self
      end

      protected

      def assert_permitted_keys!
        keys.each { |key| assert_permitted_key!(key) }
      end

      def assert_permitted_key!(key)
        fail KeyError, "Key #{key.inspect} is not permitted for this hash" unless self.class.permitted_keys.include?(key)
      end
    end
  end
end
