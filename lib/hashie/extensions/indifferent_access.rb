# frozen_string_literal: true

module Hashie
  module Extensions
    # IndifferentAccess gives you the ability to not care
    # whether your hash has string or symbol keys. Made famous
    # in Rails for accessing query and POST parameters, this
    # is a handy tool for making sure your hash has maximum
    # utility.
    #
    # One unique feature of this mixin is that it will recursively
    # inject itself into sub-hash instances without modifying
    # the actual class of the sub-hash.
    #
    # @example
    #   class MyHash < Hash
    #     include Hashie::Extensions::MergeInitializer
    #     include Hashie::Extensions::IndifferentAccess
    #   end
    #
    #   h = MyHash.new(:foo => 'bar', 'baz' => 'blip')
    #   h['foo'] # => 'bar'
    #   h[:foo]  # => 'bar'
    #   h[:baz]  # => 'blip'
    #   h['baz'] # => 'blip'
    #
    module IndifferentAccess
      # @api private
      def self.convert_key(key)
        return key.name if key.is_a?(Symbol)

        key.to_s
      end

      def self.included(base)
        Hashie::Extensions::Dash::IndifferentAccess.maybe_extend(base)

        base.class_eval do
          alias_method :regular_writer, :[]= unless method_defined?(:regular_writer)
          alias_method :[]=, :indifferent_writer
          alias_method :store, :indifferent_writer
          %w[default update replace fetch delete key? values_at].each do |m|
            alias_method "regular_#{m}", m unless method_defined?("regular_#{m}")
            alias_method m, "indifferent_#{m}"
          end

          %w[include? member? has_key?].each do |key_alias|
            alias_method key_alias, :indifferent_key?
          end

          class << self
            def [](*)
              super.convert!
            end

            def try_convert(*)
              (hash = super) && self[hash]
            end
          end
        end
      end

      # This will inject indifferent access into an instance of
      # a hash without modifying the actual class. This is what
      # allows IndifferentAccess to spread to sub-hashes.
      #
      # @example Convert an existing hash in place
      #   hash = { user: { name: 'Ada' } }
      #   Hashie::Extensions::IndifferentAccess.inject!(hash)
      #   hash['user'][:name] # => 'Ada'
      #   hash.class # => Hash
      def self.inject!(hash)
        (class << hash; self; end).send :include, IndifferentAccess
        hash.convert!
      end

      # Injects indifferent access into a duplicate of the hash
      # provided. See #inject!
      #
      # @example Leave the original hash's top-level keys unchanged
      #   original = { name: 'Ada' }
      #   hash = Hashie::Extensions::IndifferentAccess.inject(original)
      #   hash['name'] # => 'Ada'
      #   original # => { name: 'Ada' }
      def self.inject(hash)
        inject!(hash.dup)
      end

      # @example Normalize symbol keys
      #   hash = Hashie::Extensions::IndifferentAccess.inject({})
      #   hash.convert_key(:name) # => 'name'
      def convert_key(key)
        IndifferentAccess.convert_key(key)
      end

      # Iterates through the keys and values, reconverting them to
      # their proper indifferent state. Used when IndifferentAccess
      # is injecting itself into member hashes.
      #
      # @example Normalize keys inserted through the original writer
      #   hash = Hashie::Extensions::IndifferentAccess.inject({})
      #   hash.regular_writer(:name, 'Ada')
      #   hash.convert!
      #   hash.keys # => ['name']
      #   hash[:name] # => 'Ada'
      def convert!
        keys.each do |k| # rubocop:disable Performance/HashEachMethods
          indifferent_writer k, regular_delete(k)
        end
        self
      end

      # @example Make hashes nested in arrays indifferent
      #   hash = Hashie::Extensions::IndifferentAccess.inject({})
      #   value = hash.indifferent_value([{ name: 'Ada' }])
      #   value.first['name'] # => 'Ada'
      def indifferent_value(value)
        if _hash_lacking_indifference?(value)
          IndifferentAccess.inject!(value)
        elsif value.is_a?(::Array)
          value.replace(value.map { |e| indifferent_value(e) })
        else
          value
        end
      end

      # @example Return an existing value or the configured default
      #   hash = Hashie::Extensions::IndifferentAccess.inject({ name: 'Ada' })
      #   hash.default = 'unknown'
      #   hash.indifferent_default(:name) # => 'Ada'
      #   hash.indifferent_default(:missing) # => 'unknown'
      def indifferent_default(key = nil)
        return self[convert_key(key)] if key?(key)

        regular_default(key)
      end

      # @example Normalize incoming keys and nested values
      #   hash = Hashie::Extensions::IndifferentAccess.inject({})
      #   hash.indifferent_update(user: { name: 'Ada' })
      #   hash['user']['name'] # => 'Ada'
      def indifferent_update(other_hash)
        return regular_update(other_hash) if _hash_with_indifference?(other_hash)

        other_hash.each_pair do |k, v|
          self[k] = v
        end
      end

      # @example Store a symbol key as a string
      #   hash = Hashie::Extensions::IndifferentAccess.inject({})
      #   hash.indifferent_writer(:name, 'Ada')
      #   hash # => { 'name' => 'Ada' }
      def indifferent_writer(key, value)
        regular_writer convert_key(key), indifferent_value(value)
      end

      # @example Fetch with either key type and support fallbacks
      #   hash = Hashie::Extensions::IndifferentAccess.inject({ name: 'Ada' })
      #   hash.indifferent_fetch(:name) # => 'Ada'
      #   hash.indifferent_fetch(:missing, 'unknown') # => 'unknown'
      def indifferent_fetch(key, ...)
        regular_fetch(convert_key(key), ...)
      end

      # @example Delete a string key through a symbol
      #   hash = Hashie::Extensions::IndifferentAccess.inject({ name: 'Ada' })
      #   hash.indifferent_delete(:name) # => 'Ada'
      #   hash # => {}
      def indifferent_delete(key)
        regular_delete convert_key(key)
      end

      # @example Recognize both key representations
      #   hash = Hashie::Extensions::IndifferentAccess.inject({ name: 'Ada' })
      #   hash.indifferent_key?(:name) # => true
      #   hash.indifferent_key?('name') # => true
      def indifferent_key?(key)
        regular_key? convert_key(key)
      end

      # @example Retrieve values using mixed key types
      #   hash = Hashie::Extensions::IndifferentAccess.inject({ name: 'Ada', age: 42 })
      #   hash.indifferent_values_at(:name, 'age', :missing) # => ['Ada', 42, nil]
      def indifferent_values_at(*indices)
        indices.map { |i| self[i] }
      end

      # @example Identify an indifferent hash
      #   hash = Hashie::Extensions::IndifferentAccess.inject({})
      #   hash.indifferent_access? # => true
      def indifferent_access?
        true
      end

      # @example Replace existing data and convert incoming keys
      #   hash = Hashie::Extensions::IndifferentAccess.inject({ old: true })
      #   hash.indifferent_replace(name: 'Ada')
      #   hash # => { 'name' => 'Ada' }
      def indifferent_replace(other_hash)
        (keys - other_hash.keys).each { |key| delete(key) }
        other_hash.each { |key, value| self[key] = value }
        self
      end

      # @example Merge without changing the original
      #   hash = Hashie::Extensions::IndifferentAccess.inject({ name: 'Ada' })
      #   merged = hash.merge(age: 42)
      #   merged[:age] # => 42
      #   merged.indifferent_access? # => true
      #   hash.key?(:age) # => false
      def merge(*args)
        result = super
        return IndifferentAccess.inject!(result) if _hash_lacking_indifference?(result)

        result.convert!
      end

      # @example Merge and normalize in place
      #   hash = Hashie::Extensions::IndifferentAccess.inject({ name: 'Ada' })
      #   hash.merge!(age: 42)
      #   hash['age'] # => 42
      #   hash.keys.sort # => ['age', 'name']
      def merge!(*)
        super.convert!
      end

      # @example Export a regular hash, preserving its default
      #   hash = Hashie::Extensions::IndifferentAccess.inject({ name: 'Ada' })
      #   hash.default = 'unknown'
      #   plain = hash.to_hash
      #   plain # => { 'name' => 'Ada' }
      #   plain[:name] # => 'unknown'
      #   plain.respond_to?(:indifferent_access?) # => false
      def to_hash
        {}.tap do |result|
          each_pair { |key, value| result[key] = value }

          if default_proc
            result.default_proc = default_proc
          else
            result.default = default
          end
        end
      end

      # @example Select keys using either representation
      #   hash = Hashie::Extensions::IndifferentAccess.inject({ name: 'Ada', age: 42 })
      #   hash.slice(:name) # => { 'name' => 'Ada' }
      def slice(*keys)
        string_keys = keys.map { |key| convert_key(key) }
        super(*string_keys)
      end

      # @example Exclude keys using either representation
      #   hash = Hashie::Extensions::IndifferentAccess.inject({ name: 'Ada', age: 42 })
      #   hash.except(:age) # => { 'name' => 'Ada' }
      def except(*keys)
        string_keys = keys.map { |key| convert_key(key) }
        super(*string_keys)
      end

      private

      def _hash_lacking_indifference?(other)
        other.is_a?(::Hash) &&
          !(other.respond_to?(:indifferent_access?) &&
            other.indifferent_access?)
      end

      def _hash_with_indifference?(other)
        other.is_a?(::Hash) &&
          other.respond_to?(:indifferent_access?) &&
          other.indifferent_access?
      end
    end
  end
end
