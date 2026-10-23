# frozen_string_literal: true

module Hashie
  # @example Describe a failed conversion
  #   require 'hashie/extensions/coercion'
  #   error = Hashie::CoercionError.new(:age, 'bad', Integer, 'invalid number')
  #   error.message # => 'cannot coerce property `:age` from `String` to `Integer`: invalid number'
  class CoercionError < StandardError
    # @example Include the key, source class, and destination in the message
    #   require 'hashie/extensions/coercion'
    #   error = Hashie::CoercionError.new(:age, 'bad', Integer, 'invalid number')
    #   error.message # => 'cannot coerce property `:age` from `String` to `Integer`: invalid number'
    def initialize(key, value, into, message)
      super("cannot coerce property `#{key.inspect}` from `#{value.class}` to `#{into}`: #{message}")
    end
  end

  module Extensions
    # @example Coerce assigned values
    #   class Person < Hash
    #     include Hashie::Extensions::Coercion
    #     coerce_key :age, Integer
    #   end
    #   person = Person.new
    #   person[:age] = '42'
    #   person[:age] # => 42
    module Coercion
      CORE_TYPES = {
        Integer => :to_i,
        Float => :to_f,
        Complex => :to_c,
        Rational => :to_r,
        String => :to_s,
        Symbol => :to_sym
      }.freeze

      ABSTRACT_CORE_TYPES =
        { Numeric => [Integer, Float, Complex, Rational] }.freeze

      def self.included(base)
        base.send :include, InstanceMethods
        base.extend ClassMethods
        base.send :alias_method, :set_value_without_coercion, :[]= unless base.method_defined?(:set_value_without_coercion)
        base.send :alias_method, :[]=, :set_value_with_coercion
      end

      # @example Add coercing instance writers through the extension
      #   class Record < Hash
      #     include Hashie::Extensions::Coercion
      #     coerce_key :count, Integer
      #   end
      #   record = Record.new
      #   record[:count] = '3'
      #   record[:count] # => 3
      module InstanceMethods
        # @example Write a coerced value
        #   class Record < Hash
        #     include Hashie::Extensions::Coercion
        #     coerce_key :count, Integer
        #   end
        #   record = Record.new
        #   record.set_value_with_coercion(:count, '3')
        #   record[:count] # => 3
        def set_value_with_coercion(key, value)
          into = self.class.key_coercion(key) || self.class.value_coercion(value)

          unless value.nil? || into.nil?
            begin
              value = self.class.fetch_coercion(into).call(value)
            rescue NoMethodError, TypeError, ArgumentError => e
              raise CoercionError.new(key, value, into, e.message)
            end
          end

          set_value_without_coercion(key, value)
        end

        # @example Route a custom write through coercion
        #   class Record < Hash
        #     include Hashie::Extensions::Coercion
        #     coerce_key :count, Integer
        #   end
        #   record = Record.new
        #   record.custom_writer(:count, '3')
        #   record[:count] # => 3
        def custom_writer(key, value, _convert = true)
          self[key] = value
        end

        # Ensures that values are coerced before Mash's own recursive
        # Hash-to-Mash conversion has a chance to run, since by that point
        # the value would already be an instance of `self.class` rather
        # than a plain Hash, and value coercion would never trigger. See
        # https://github.com/hashie/hashie/issues/265.
        #
        # @example Convert values by their source type
        #   class Record < Hash
        #     include Hashie::Extensions::Coercion
        #     coerce_value String, Integer
        #   end
        #   Record.new.convert_value('3') # => 3
        #   Record.new.convert_value(false) # => false
        def convert_value(val, duping = false)
          into = self.class.value_coercion(val)
          return self.class.fetch_coercion(into).call(val) if into

          defined?(super) ? super : val
        end

        # @example Remove old keys and coerce incoming values
        #   class Record < Hash
        #     include Hashie::Extensions::Coercion
        #     coerce_key :count, Integer
        #   end
        #   record = Record[:old, true]
        #   record.replace(count: '3')
        #   record # => { count: 3 }
        def replace(other_hash)
          (keys - other_hash.keys).each { |key| delete(key) }
          other_hash.each { |key, value| self[key] = value }
          self
        end
      end

      # @example Configure coercion rules on a hash subclass
      #   class Record < Hash
      #     include Hashie::Extensions::Coercion
      #     coerce_key :count, Integer
      #   end
      #   Record.key_coercion(:count) # => Integer
      module ClassMethods
        attr_writer :key_coercions
        protected :key_coercions=

        # Set up a coercion rule such that any time the specified
        # key is set it will be coerced into the specified class.
        # Coercion will occur by first attempting to call Class.coerce
        # and then by calling Class.new with the value as an argument
        # in either case. Procs and other objects implementing #call
        # may also be used.
        #
        # @param [Array<Object>] attrs the keys followed by the class or callable used to coerce them.
        #
        # @example Coerce a "user" subhash into a User object
        #   User = Struct.new(:name) do
        #     def self.coerce(attributes)
        #       new(attributes[:name])
        #     end
        #   end
        #   class Tweet < Hash
        #     include Hashie::Extensions::Coercion
        #     coerce_key :user, User
        #   end
        #   tweet = Tweet.new
        #   tweet[:user] = { name: 'Ada' }
        #   tweet[:user].name # => 'Ada'
        def coerce_key(*attrs)
          into = attrs.pop
          attrs.each { |key| key_coercions[key] = into }
        end

        # @example Configure multiple keys with one rule
        #   class Record < Hash
        #     include Hashie::Extensions::Coercion
        #     coerce_keys :count, :total, Integer
        #   end
        #   record = Record.new
        #   record[:total] = '12'
        #   record[:total] # => 12
        #   Record.key_coercion(:count) # => Integer
        alias coerce_keys coerce_key

        # Returns a hash of any existing key coercions.
        #
        # @example Inspect configured rules
        #   klass = Class.new(Hash) { include Hashie::Extensions::Coercion }
        #   klass.coerce_key(:age, Integer)
        #   klass.key_coercions # => { age: Integer }
        def key_coercions
          @key_coercions ||= {}
        end

        # Returns the specific key coercion for the specified key,
        # if one exists.
        #
        # @example Look up symbol and string key names
        #   klass = Class.new(Hash) { include Hashie::Extensions::Coercion }
        #   klass.coerce_key(:age, Integer)
        #   klass.key_coercion('age') # => Integer
        #   klass.key_coercion(:missing) # => nil
        def key_coercion(key)
          key_coercions[key.to_sym]
        end

        # Set up a coercion rule such that any time a value of the
        # specified type is set it will be coerced into the specified
        # class.
        #
        # @param [Class] from the type you would like coerced.
        # @param [Class, #call] into the class or callable used to coerce the value.
        # @option options [Boolean] :strict (true) whether use exact source class
        #   only or include ancestors
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
        #   record = SpecialHash.new
        #   record[:user] = { name: 'Ada' }
        #   record[:user].class # => SpecialHash
        #   record[:user][:name] # => 'Ada'
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
        #
        # @example Inspect exact source-type rules
        #   klass = Class.new(Hash) { include Hashie::Extensions::Coercion }
        #   klass.coerce_value(String, Integer)
        #   klass.strict_value_coercions # => { String => Integer }
        def strict_value_coercions
          @strict_value_coercions ||= {}
        end

        # Return all value coercions that have the :strict rule as false.
        #
        # @example Inspect non-strict source-type rules
        #   klass = Class.new(Hash) { include Hashie::Extensions::Coercion }
        #   klass.coerce_value(Integer, String, strict: false)
        #   klass.lenient_value_coercions # => { Integer => String }
        def lenient_value_coercions
          @lenient_value_coercions ||= {}
        end

        # Fetch the value coercion, if any, for the specified object.
        #
        # @example Look up a rule from an actual value
        #   klass = Class.new(Hash) { include Hashie::Extensions::Coercion }
        #   klass.coerce_value(String, Integer)
        #   klass.value_coercion('3') # => Integer
        #   klass.value_coercion(false) # => nil
        def value_coercion(value)
          from = value.class
          strict_value_coercions[from] || lenient_value_coercions[from]
        end

        # @example Retrieve a conversion callable
        #   klass = Class.new(Hash) { include Hashie::Extensions::Coercion }
        #   klass.fetch_coercion(Integer).call('3') # => 3
        #   klass.fetch_coercion(->(value) { value.upcase }).call('ada') # => 'ADA'
        def fetch_coercion(type)
          return type if type.is_a? Proc
          return type if type.respond_to?(:call) && !type.is_a?(Module) && !type.is_a?(Enumerable)

          coercion_cache[type]
        end

        # @example Lazily cache a working conversion
        #   klass = Class.new(Hash) { include Hashie::Extensions::Coercion }
        #   conversion = klass.coercion_cache[Integer]
        #   conversion.call('3') # => 3
        #   klass.coercion_cache[Integer].equal?(conversion) # => true
        def coercion_cache
          @coercion_cache ||= ::Hash.new do |hash, type|
            hash[type] = build_coercion(type)
          end
        end

        # @example Build scalar and nested collection conversions
        #   klass = Class.new(Hash) { include Hashie::Extensions::Coercion }
        #   klass.build_coercion(Integer).call('3') # => 3
        #   klass.build_coercion([Integer]).call(['3', '4']) # => [3, 4]
        #   klass.build_coercion({ Symbol => Integer }).call('age' => '42') # => { age: 42 }
        def build_coercion(type)
          if type.is_a? Enumerable
            if type.instance_of?(::Hash)
              type, key_type, value_type = type.class, *type.first
              build_hash_coercion(type, key_type, value_type)
            else
              value_type = type.first
              type = type.class
              build_container_coercion(type, value_type)
            end
          elsif CORE_TYPES.key? type
            build_core_type_coercion(type)
          elsif type.respond_to? :coerce
            lambda do |value|
              return value if value.is_a? type

              type.coerce(value)
            end
          elsif type.respond_to? :new
            lambda do |value|
              return value if value.is_a? type

              type.new(value)
            end
          else
            raise TypeError, "no coercion is available for `#{type}`"
          end
        end

        # @example Convert both hash keys and values
        #   klass = Class.new(Hash) { include Hashie::Extensions::Coercion }
        #   conversion = klass.build_hash_coercion(Hash, Symbol, Integer)
        #   conversion.call('age' => '42') # => { age: 42 }
        def build_hash_coercion(type, key_type, value_type)
          key_coerce = fetch_coercion(key_type)
          value_coerce = fetch_coercion(value_type)
          lambda do |value|
            type[value.map { |k, v| [key_coerce.call(k), value_coerce.call(v)] }]
          end
        end

        # @example Convert each array element
        #   klass = Class.new(Hash) { include Hashie::Extensions::Coercion }
        #   conversion = klass.build_container_coercion(Array, Integer)
        #   conversion.call(['3', '4']) # => [3, 4]
        def build_container_coercion(type, value_type)
          value_coerce = fetch_coercion(value_type)
          lambda do |value|
            type.new(value.map { |v| value_coerce.call(v) })
          end
        end

        # @example Use the lenient core conversion
        #   klass = Class.new(Hash) { include Hashie::Extensions::Coercion }
        #   conversion = klass.build_core_type_coercion(Integer)
        #   conversion.call('12 items') # => 12
        #   conversion.call('not a number') # => 0
        def build_core_type_coercion(type)
          name = CORE_TYPES[type]
          lambda do |value|
            return value if value.is_a? type

            value.send(name)
          end
        end

        # @example Copy key rules into subclasses without sharing their rule hashes
        #   parent = Class.new(Hash) { include Hashie::Extensions::Coercion }
        #   parent.coerce_key(:age, Integer)
        #   child = Class.new(parent)
        #   child.coerce_key(:name, String)
        #   child.key_coercion(:age) # => Integer
        #   parent.key_coercion(:name) # => nil
        def inherited(klass)
          super

          klass.key_coercions = key_coercions.dup
        end
      end
    end
  end
end
