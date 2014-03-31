module Hashie
  module Extensions
    module Coercion
      def self.included(base)
        base.extend ClassMethods
        base.send :include, InstanceMethods
      end

      module InstanceMethods
        def []=(key, value)
          into = self.class.key_coercion(key) || self.class.value_coercion(value)

          if value && into
            if into.respond_to?(:coerce)
              value = into.coerce(value)
            else
              value = into.new(value)
            end
          end

          super(key, value)
        end

        def custom_writer(key, value, convert = true)
          self[key] = value
        end

        def replace(other_hash)
          (keys - other_hash.keys).each { |key| delete(key) }
          other_hash.each { |key, value| self[key] = value }
          self
        end
      end

      module ClassMethods
        # Set up a coercion rule such that any time the specified
        # key is set it will be coerced into the specified class.
        # Coercion will occur by first attempting to call Class.coerce
        # and then by calling Class.new with the value as an argument
        # in either case.
        #
        # @param [Object] key the key or array of keys you would like to be coerced.
        # @param [Class] into the class into which you want the key(s) coerced.
        #
        # @example Coerce a "user" subhash into a User object
        #   class Tweet < Hash
        #     include Hashie::Extensions::Coercion
        #     coerce_key :user, User
        #   end
        def coerce_key(*attrs)
          @key_coercions ||= {}
          into = attrs.pop
          attrs.each { |key| @key_coercions[key] = into }
        end

        alias_method :coerce_keys, :coerce_key

        # Returns a hash of any existing key coercions.
        def key_coercions
          @key_coercions || {}
        end

        # Returns the specific key coercion for the specified key,
        # if one exists.
        def key_coercion(key)
          key_coercions[key.to_sym]
        end

        # Set up a coercion rule such that any time a value of the
        # specified type is set it will be coerced into the specified
        # class.
        #
        # @param [Class] from the type you would like coerced.
        # @param [Class] into the class into which you would like the value coerced.
        # @option options [Boolean] :strict (true) whether use exact source class only or include ancestors
        #
        # @example Coerce all hashes into this special type of hash
        #   class SpecialHash < Hash
        #     include Hashie::Extensions::Coercion
        #     coerce_value Hash, SpecialHash
        #
        #     def initialize(hash = {})
        #       super
        #       hash.each_pair do |k,v|
        #         self[k] = v
        #       end
        #     end
        #   end
        def coerce_value(from, into, options = {})
          options = { strict: true }.merge(options)

          if options[:strict]
            (@strict_value_coercions ||= {})[from] = into
          else
            while from.superclass && from.superclass != Object
              (@lenient_value_coercions ||= {})[from] = into
              from = from.superclass
            end
          end
        end

        # Return all value coercions that have the :strict rule as true.
        def strict_value_coercions
          @strict_value_coercions || {}
        end
        # Return all value coercions that have the :strict rule as false.
        def lenient_value_coercions
          @value_coercions || {}
        end

        # Fetch the value coercion, if any, for the specified object.
        def value_coercion(value)
          from = value.class
          strict_value_coercions[from] || lenient_value_coercions[from]
        end
      end
    end
  end
end
