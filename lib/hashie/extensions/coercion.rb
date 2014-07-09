module Hashie
  module Extensions
    module Coercion
      def self.included(base)
        base.send :include, InstanceMethods
        base.extend ClassMethods # NOTE: we wanna make sure we first define set_value_with_coercion before extending

        base.send :alias_method, :'set_value_without_coercion', :[]=
        base.send :alias_method, :[]=, :'set_value_with_coercion'
      end

      module InstanceMethods
        def set_value_with_coercion(key, value)
          into = self.class.key_coercion(key) || self.class.value_coercion(value)

          return set_value_without_coercion(key, value) unless value && into
          return set_value_without_coercion(key, coerce_or_init(into).call(value)) unless into.is_a?(Enumerable)

          if into.class >= Hash
            key_coerce = coerce_or_init(into.flatten[0])
            value_coerce = coerce_or_init(into.flatten[-1])
            value = Hash[value.map { |k, v| [key_coerce.call(k), value_coerce.call(v)] }]
          else # Enumerable but not Hash: Array, Set
            value_coerce = coerce_or_init(into.first)
            value = into.class.new(value.map { |v| value_coerce.call(v) })
          end

          set_value_without_coercion(key, value)
        end

        def coerce_or_init(type)
          type.respond_to?(:coerce) ? ->(v) { type.coerce(v) } : ->(v) { type.new(v) }
        end

        private :coerce_or_init

        def custom_writer(key, value, _convert = true)
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
