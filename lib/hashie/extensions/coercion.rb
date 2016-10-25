module Hashie
  class CoercionError < StandardError; end

  module Extensions
    module Coercion
      ABSTRACT_CORE_TYPES = {
        Integer => [Fixnum, Bignum],
        Numeric => [Fixnum, Bignum, Float, Complex, Rational]
      }

      class CoercionSystemIncludeBuilder < Module
        attr_reader :common_included_block

        def initialize(&common_included_block)
          @common_included_block = common_included_block
        end

        def define_include_type_method(base_module, name, &type_system_block)
          common_included_block = @common_included_block
          base_module.define_singleton_method name do
            Module.new.tap do |mod|
              mod.define_singleton_method :included do |base|
                instance_exec(base, &common_included_block)
                instance_exec(base, &type_system_block)
              end
            end
          end
        end

        def define_default_included(base_module, &default_system_block)
          common_included_block = @common_included_block
          base_module.define_singleton_method :included do |base|
            instance_exec(base, &common_included_block)
            instance_exec(base, &default_system_block)
          end
        end

        # New Coercion systems must override the base_class here.
        def extended(base)
          define_default_included base do |base_class|
            base_class.extend HashieTypes
          end
          define_include_type_method base, :active_model do |base_class|
            base_class.extend ActiveModel
          end
        end
      end

      Includer = CoercionSystemIncludeBuilder.new do |base|
        base.include InstanceMethods
        base.extend ClassMethods
        unless base.method_defined?(:set_value_without_coercion)
          base.send :alias_method, :set_value_without_coercion, :[]=
        end
        base.send :alias_method, :[]=, :set_value_with_coercion
      end
      extend Includer

      module InstanceMethods
        def set_value_with_coercion(key, value)
          into = self.class.key_coercion(key) || self.class.value_coercion(value)

          unless value.nil? || into.nil?
            begin
              value = self.class.fetch_coercion(into).call(value)
            rescue NoMethodError, TypeError => e
              raise CoercionError, "Cannot coerce property #{key.inspect} from #{value.class} to #{into}: #{e.message}"
            end
          end

          set_value_without_coercion(key, value)
        end

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
        attr_writer :key_coercions
        protected :key_coercions=

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
          into = attrs.pop
          attrs.each { |key| key_coercions[key] = into }
        end

        alias_method :coerce_keys, :coerce_key

        # Returns a hash of any existing key coercions.
        def key_coercions
          @key_coercions ||= {}
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

          if ABSTRACT_CORE_TYPES.key? from
            ABSTRACT_CORE_TYPES[from].each do |type|
              coerce_value type, into, options
            end
          end

          if options[:strict]
            strict_value_coercions[from] = into
          else
            while from.superclass && from.superclass != Object
              lenient_value_coercions[from] = into
              from = from.superclass
            end
          end
        end

        # Return all value coercions that have the :strict rule as true.
        def strict_value_coercions
          @strict_value_coercions ||= {}
        end

        # Return all value coercions that have the :strict rule as false.
        def lenient_value_coercions
          @lenient_value_coercions ||= {}
        end

        # Fetch the value coercion, if any, for the specified object.
        def value_coercion(value)
          from = value.class
          strict_value_coercions[from] || lenient_value_coercions[from]
        end

        def fetch_coercion(type)
          return type if type.is_a? Proc
          coercion_cache[type]
        end

        def coercion_cache
          @coercion_cache ||= ::Hash.new do |hash, type|
            hash[type] = build_coercion(type)
          end
        end

        def build_coercion
          raise 'This method must be replaced'
        end

        def inherited(klass)
          super
          klass.key_coercions = key_coercions.dup
        end
      end
    end
  end
end
