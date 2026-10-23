# frozen_string_literal: true

module Hashie
  module Extensions
    # Extends a Hash with the ability to convert its keys to strings.
    #
    # @example Extend a pre-existing Hash object
    #   hash = { test: 'value' }
    #   hash.extend(Hashie::Extensions::StringifyKeys)
    #   hash.stringify_keys!
    #   hash # => { 'test' => 'value' }
    #
    # @example Create a Hash class with this capability
    #   class StringifyingHash < Hash
    #     include Hashie::Extensions::StringifyKeys
    #   end
    #
    #   hash = StringifyingHash.new
    #   hash[:test] = 'value'
    #   hash.stringify_keys!
    #   hash # => { 'test' => 'value' }
    #
    # @example Use the module function to stringify keys in a hash
    #   hash = { test: 'value' }
    #   Hashie::Extensions::StringifyKeys.stringify_keys!(hash)
    #   hash # => { 'test' => 'value' }
    module StringifyKeys
      # Converts all keys in the hash and nested hashes and arrays to strings.
      #
      # @example Convert keys in place
      #   test = { abc: [{ def: 'value' }] }
      #   test.extend(Hashie::Extensions::StringifyKeys)
      #   test.stringify_keys!
      #   test # => { 'abc' => [{ 'def' => 'value' }] }
      #
      # @api public
      # @return [Hash] the receiver with its keys converted to strings
      def stringify_keys!
        StringifyKeys.stringify_keys!(self)
        self
      end

      # Returns a shallow copy with all keys recursively converted to strings.
      # Nested hashes and arrays are shared with the original and are modified.
      #
      # @example Copy a flat hash without modifying the original
      #   test = { abc: 'def' }
      #   test.extend(Hashie::Extensions::StringifyKeys)
      #   test.stringify_keys # => { 'abc' => 'def' }
      #   test # => { abc: 'def' }
      #
      # @example Nested values are shared, not deep copied
      #   test = { abc: [{ def: 'value' }] }
      #   test.extend(Hashie::Extensions::StringifyKeys)
      #   test.stringify_keys # => { 'abc' => [{ 'def' => 'value' }] }
      #   test # => { abc: [{ 'def' => 'value' }] }
      #
      # @api public
      # @return [Hash] a shallow copy with stringified keys
      def stringify_keys
        StringifyKeys.stringify_keys(self)
      end

      # @example Add recursive conversion functions to an object
      #   converter = Object.new.extend(Hashie::Extensions::StringifyKeys::ClassMethods)
      #   converter.stringify_keys(user: { name: 'Ada' }) # => { 'user' => { 'name' => 'Ada' } }
      module ClassMethods
        # Stringify all keys recursively within nested
        # hashes and arrays.
        # @api private
        def stringify_keys_recursively!(object)
          case object
          when ::Array
            object.each do |i|
              stringify_keys_recursively!(i)
            end
          when ::Hash
            stringify_keys!(object)
          end
        end

        # Converts all keys in a hash recursively to strings, in place.
        #
        # @example Convert keys through Hashie's module function
        #   test = { abc: 'def' }
        #   Hashie.stringify_keys!(test)
        #   test # => { 'abc' => 'def' }
        #
        # @api public
        # @param [Hash] hash
        # @return [Hash] the passed hash with stringified keys
        def stringify_keys!(hash)
          hash.extend(Hashie::Extensions::StringifyKeys) unless hash.respond_to?(:stringify_keys!)
          hash.keys.each do |k| # rubocop:disable Performance/HashEachMethods
            stringify_keys_recursively!(hash[k])
            hash[k.to_s] = hash.delete(k)
          end
          hash
        end

        # Returns a shallow copy of a hash with recursively stringified keys.
        # Nested hashes and arrays are shared with the original and are modified.
        #
        # @example Copy keys through Hashie's module function
        #   test = { abc: 'def' }
        #   Hashie.stringify_keys(test) # => { 'abc' => 'def' }
        #   test # => { abc: 'def' }
        #
        # @api public
        # @param [Hash] hash
        # @return [Hash] a shallow copy with stringified keys
        def stringify_keys(hash)
          copy = hash.dup
          copy.extend(Hashie::Extensions::StringifyKeys) unless copy.respond_to?(:stringify_keys!)
          copy.tap do |new_hash|
            stringify_keys!(new_hash)
          end
        end
      end

      class << self
        include ClassMethods
      end
    end
  end
end
