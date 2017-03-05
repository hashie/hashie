module Hashie
  # Raised when a value is not able to be coerced to a new type
  class CoercionError < StandardError; end

  module Extensions
    # Extends a Hash to have the ability to coerce its values to new types
    #
    # @example Create a JobStatus class with integer ids and string statuses
    #   class JobStatus < Hash
    #     include Hashie::Extensions::Coercion
    #
    #     coerce_key :id, Integer
    #     coerce_key :status, String
    #   end
    #
    #   job = JobStatus.new
    #   job[:id] = "123"
    #   job[:status] = :active
    #   job  #=> {:id => 123, :status => "active"}
    #
    # @example Create a Hash that coerces all nested hashes to User objects
    #   class User
    #     attr_reader :username
    #
    #     def initialize(username:)
    #       @username = username
    #     end
    #   end
    #
    #   class Tweet < Hash
    #     include Hashie::Extensions::Coercion
    #
    #     coerce_value Hash, User
    #   end
    #
    #   tweet = Tweet.new
    #   tweet[:author] = {:username => "yukihiro_matz"}
    #   tweet[:content] = "Hello!"
    #   tweet  #=> {:author => #<User: @username="yukihiro_matz">, :content => "Hello!"}
    #
    # @example Create a hash that coerces a hash of users and their relations
    #   class Person
    #     def initialize(attrs = {})
    #       attrs.each { |key, value| instance_variable_set("@#{key}", value) }
    #     end
    #
    #     attr_reader :name
    #   end
    #
    #   class Relation
    #     def initialize(attrs = {})
    #       attrs.each { |key, value| instance_variable_set("@#{key}", value) }
    #     end
    #
    #     attr_reader :type
    #   end
    #
    #   class Family < Hash
    #     include Hashie::Extensions::Coercion
    #
    #     coerce_key :relationships, Hash[Person => Relation]
    #   end
    #
    #   relationships = {}
    #   relationships["name" => "Bilbo"] = {"type" => "uncle"}
    #   relationships["name" => "Frodo"] = {"type" => "nephew"}
    #
    #   family = Family.new
    #   family[:relationships] = relationships
    #   #=> {:relationships => {
    #   #=>   #<Person @name="Bilbo"}> => #<Relation @type="uncle">,
    #   #=>   #<Person @name="Frodo"}> => #<Relation @type="nephew">
    #   #=> }}
    module Coercion
      # A mapping of core type classes to methods to use for coercing to them
      #
      # @api private
      # @return [Hash]
      CORE_TYPES = {
        Integer    => :to_i,
        Float      => :to_f,
        Complex    => :to_c,
        Rational   => :to_r,
        String     => :to_s,
        Symbol     => :to_sym
      }

      # A mapping of core abstract classes to their concrete classes
      #
      # @api private
      # @return [Hash]
      ABSTRACT_CORE_TYPES = if RubyVersion.new(RUBY_VERSION) >= RubyVersion.new('2.4.0')
                              { Numeric => [Integer, Float, Complex, Rational] }
                            else
                              {
                                Integer => [Fixnum, Bignum],
                                Numeric => [Fixnum, Bignum, Float, Complex, Rational]
                              }
                            end

      # A hook that is called when the module is included in a class
      #
      # @api private
      # @param [Class] base the baseclass that is including the module
      # @return [void]
      def self.included(base)
        base.send :include, InstanceMethods
        base.extend ClassMethods # NOTE: we wanna make sure we first define set_value_with_coercion before extending

        base.send :alias_method, :set_value_without_coercion, :[]= unless base.method_defined?(:set_value_without_coercion)
        base.send :alias_method, :[]=, :set_value_with_coercion
      end

      # The instance methods to include in any including classes.
      module InstanceMethods
        # Sets the value of a key to a coerced version of the original value
        #
        # @api private
        # @param [#hash] the key to store in the hash
        # @param [Object] the value to coerce before storing in the hash
        # @return [void]
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

        # Hook method for overriding any custom writer in the base class
        #
        # @note This method allows the coercion module to work in {Hashie::Mash}.
        #
        # @api private
        # @param [#hash] key the key to store in the hash
        # @param [Object] value the value of the key to store in the hash
        # @param [Boolean] _convert whether to coerce the value
        # @return [void]
        def custom_writer(key, value, _convert = true)
          self[key] = value
        end

        # Replaces the original keys and values with coerced replacements
        #
        # This acts much like the `Hash#merge!` method, but coerces the values
        # based on the configured coercions before setting them in the hash.
        #
        # @example Replace the `id` and `status` fields in a job status
        #   class JobStatus < Hash
        #     include Hashie::Extensions::Coercion
        #     coerce_key, :id, Integer
        #     coerce_key, :status, Symbol
        #   end
        #
        #   job = JobStatus.new
        #   job[:id] = 456
        #   job[:status] = :stale
        #   job  #=> {:id => 456, :status => :stale}
        #   job.replace(:id => "123", :status => "active")
        #   job  #=> {:id => 123, :status => :active}
        #
        # @api public
        # @param [Hash] other_hash the hash to use for replacement
        # @return [Hash] the receiver (i.e. `self`) after modification
        def replace(other_hash)
          (keys - other_hash.keys).each { |key| delete(key) }
          other_hash.each { |key, value| self[key] = value }
          self
        end
      end

      # The DSL methods for configuring coercions in the base class
      module ClassMethods
        # Sets the map of keys to coercions in the base class
        #
        # @note This is a protected method because we have to track coercions
        #   across subclasses of any classes that include the module. This is
        #   _not_ a public API and should not be used by a end users.
        #
        # @api private
        # @return [Hash{Symbol => Class, Array<Class>}]
        attr_writer :key_coercions
        protected :key_coercions=

        # Declares a set of keys as coercible based on a callable or class
        #
        # You can specify any number of keys in this method. All keys will be
        # coerced based on the coercion specified (i.e. the last term you give
        # to the function).
        #
        # When you pass a class as the coercion, it will first try calling the
        # `Class.coerce` method on the value. If this fails, the value will be
        # coerced via `Class.new`. You can use this knowledge to build custom
        # coercions for you data classes.
        #
        # You can also pass an array containing a class (e.g. `Array[User]`)
        # as the coercion to coerce a collection of values for a key.
        #
        # @example Coerce a "user" subhash into a User object
        #   class Tweet < Hash
        #     include Hashie::Extensions::Coercion
        #     coerce_key :user, User
        #   end
        #
        # @example Coerce an array of "commenters" into a User objects
        #   class Post < Hash
        #     include Hashie::Extensions::Coercion
        #     coerce_key :commenters, Array[User]
        #   end
        #
        # @api public
        # @param [Object] key the key or array of keys you would like to be coerced.
        # @param [Class, Array<Class>] into the class to coerce the key(s) into
        # @return [void]
        def coerce_key(*attrs)
          into = attrs.pop
          attrs.each { |key| key_coercions[key] = into }
        end

        # !@method coerce_keys(*attrs)
        #   @see coerce_key
        alias_method :coerce_keys, :coerce_key

        # The mapping of keys to any coercions set up for them
        #
        # @api private
        # @return [Hash{Symbol => Class, Array<Class>}]
        def key_coercions
          @key_coercions ||= {}
        end

        # The specific coercion for the specified key, if any was specified
        #
        # @api private
        # @return [Class, Array<Class>, nil]
        def key_coercion(key)
          key_coercions[key.to_sym]
        end

        # Declares a coercion rule for coercing all values of a type
        #
        # A value coercion is a blanket coercion for any value that is set in
        # the hash. For example, you might want to build a JSON wrapper object
        # that symbolizes all keys for any nested JSON object. You can use a
        # value coercion to coerce all nested Hash values to your special JSON
        # wrapper hash that symbolizes all incoming keys.
        #
        # @example Coerce all nested hashes into a hash that symbolizes its keys
        #   class JSONWrapper < Hash
        #     include Hashie::Extensions::Coercion
        #
        #     coerce_value Hash, JSONWrapper
        #
        #     def initialize(hash = {})
        #       super
        #       hash.each_pair { |key, value| self[key.to_sym] = value }
        #     end
        #   end
        #
        #   hash = JSONWrapper.new(
        #     "id" => 123,
        #     "status" => "active",
        #     "object" => {
        #       "id" => 456,
        #       "type" => "site"
        #     }
        #   )
        #   hash
        #   #=> {:id => 123, :status => "active",
        #   #=>  :object => {:id => 456, :type => "site"}}
        #   hash[:object].class  #=> JSONWrapper
        #
        # @api public
        # @param [Class] from the type you would like coerced
        # @param [Class] into the class to coerce the `from` class into
        # @param [Hash] options a set of options to customize the coercion
        # @option options [Boolean] :strict (true) whether to coerce only exact
        #   class matches or both exact class matches and superclass matches
        # @return [void]
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

        # The value coercions that only apply to direct class matches
        #
        # @api private
        # @return [Hash{Class => Class}]
        def strict_value_coercions
          @strict_value_coercions ||= {}
        end

        # The value coercions that apply to direct and superclass matches
        #
        # @api private
        # @return [Hash{Class => Class}]
        def lenient_value_coercions
          @lenient_value_coercions ||= {}
        end

        # Fetch the value coercion, if any, for the specified object
        #
        # @note This is a publicly accessible class method to give access to
        #   the class coercions from instances of the class. This is _not_
        #   a public API and should not be used by the end user.
        #
        # @api private
        # @param [Class] value the class to look up a cocercion for
        # @return [Class, nil] the class to coerce to
        def value_coercion(value)
          from = value.class
          strict_value_coercions[from] || lenient_value_coercions[from]
        end

        # Looks up the callable coercion for a given type
        #
        # @note This is a publicly accessible class method to give access to
        #   the class coercions from instances of the class. This is _not_
        #   a public API and should not be used by the end user.
        #
        # @api private
        # @param [Class, Proc] type the type of class to coerce or an actual
        #   coercion
        # @return [Proc, nil] the coercion for the type
        def fetch_coercion(type)
          return type if type.is_a? Proc
          coercion_cache[type]
        end

        # A cache of previously created coercions
        #
        # @note This is a publicly accessible class method to give access to
        #   the class coercions from instances of the class. This is _not_
        #   a public API and should not be used by the end user.
        #
        # @api private
        # @return [Hash{Class => Proc}]
        def coercion_cache
          @coercion_cache ||= ::Hash.new do |hash, type|
            hash[type] = build_coercion(type)
          end
        end

        # Creates a coercion for a given type
        #
        # @note This is a publicly accessible class method to give access to
        #   the class coercions from instances of the class. This is _not_
        #   a public API and should not be used by the end user.
        #
        # @api private
        # @param [Class] type the type of class to coerce
        # @return [Proc] the coercion
        # @raise [TypeError] when the class is not coercible
        def build_coercion(type)
          if type.is_a? Enumerable
            if type.class <= ::Hash
              type, key_type, value_type = type.class, *type.first
              build_hash_coercion(type, key_type, value_type)
            else # Enumerable but not Hash: Array, Set
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
            fail TypeError, "#{type} is not a coercable type"
          end
        end

        # Creates a coercion for Hash values and their keys and values
        #
        # This allows you to specify the exact behavior you want when
        # coercing hashes. If you have a key that you know will cotain a
        # hash of user keys and relation values, you can specify that as
        # follows:
        #
        #     coerce_value :relation_map, Hash[User => Relation]
        #
        # @note This is a publicly accessible class method to give access to
        #   the class coercions from instances of the class. This is _not_
        #   a public API and should not be used by the end user.
        #
        # @api private
        # @param [Class] type the container type to filter the coercion to
        # @param [Class] key_type the type to convert the nested keys to
        # @param [Class] value_type the type to convert the nested values to
        # @return [Proc] the built coercion
        def build_hash_coercion(type, key_type, value_type)
          key_coerce = fetch_coercion(key_type)
          value_coerce = fetch_coercion(value_type)
          lambda do |value|
            type[value.map { |k, v| [key_coerce.call(k), value_coerce.call(v)] }]
          end
        end

        # Creates a coercion for an Enumerable collection
        #
        # @note This is a publicly accessible class method to give access to
        #   the class coercions from instances of the class. This is _not_
        #   a public API and should not be used by the end user.
        #
        # @api private
        # @param [Class] type the type of the container for the key
        # @param [Class] value_type the type of the values within the container
        # @return [Proc] the built coercion
        def build_container_coercion(type, value_type)
          value_coerce = fetch_coercion(value_type)
          lambda do |value|
            type.new(value.map { |v| value_coerce.call(v) })
          end
        end

        # Creates a coercion for a built-in core type
        #
        # @note This is a publicly accessible class method to give access to
        #   the class coercions from instances of the class. This is _not_
        #   a public API and should not be used by the end user.
        #
        # @api private
        # @param [Class] type the core type to coerce
        # @return [Proc] the built coercion
        def build_core_type_coercion(type)
          name = CORE_TYPES[type]
          lambda do |value|
            return value if value.is_a? type
            return value.send(name)
          end
        end

        # A hook that is called when an including class is subclassed
        #
        # @api private
        # @param klass [Class] the base class being inherited
        # @return [void]
        def inherited(klass)
          super

          klass.key_coercions = key_coercions.dup
        end
      end
    end
  end
end
