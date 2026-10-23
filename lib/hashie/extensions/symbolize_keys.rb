# frozen_string_literal: true

module Hashie
  module Extensions
    # Extends a Hash with the ability to convert its keys to symbols.
    # Keys that do not respond to #to_sym are preserved.
    #
    # @example Extend a pre-existing Hash object
    #   hash = { 'test' => 'value' }
    #   hash.extend(Hashie::Extensions::SymbolizeKeys)
    #   hash.symbolize_keys!
    #   hash # => { test: 'value' }
    #
    # @example Create a Hash class with this capability
    #   class SymbolizableHash < Hash
    #     include Hashie::Extensions::SymbolizeKeys
    #   end
    #
    #   hash = SymbolizableHash.new
    #   hash['test'] = 'value'
    #   hash.symbolize_keys!
    #   hash # => { test: 'value' }
    #
    # @example Use the module function to symbolize keys in a hash
    #   hash = { 'test' => 'value', 123 => 'number' }
    #   Hashie::Extensions::SymbolizeKeys.symbolize_keys!(hash)
    #   hash # => { test: 'value', 123 => 'number' }
    module SymbolizeKeys
      # Converts keys in the hash and nested hashes and arrays to symbols.
      #
      # @example Convert keys in place
      #   test = { 'abc' => [{ 'def' => 'value' }] }
      #   test.extend(Hashie::Extensions::SymbolizeKeys)
      #   test.symbolize_keys!
      #   test # => { abc: [{ def: 'value' }] }
      #
      # @api public
      # @return [Hash] the receiver with its keys symbolized where possible
      def symbolize_keys!
        SymbolizeKeys.symbolize_keys!(self)
        self
      end

      # Returns a shallow copy with keys recursively converted to symbols.
      # Nested hashes and arrays are shared with the original and are modified.
      #
      # @example Copy a flat hash without modifying the original
      #   test = { 'abc' => 'def' }
      #   test.extend(Hashie::Extensions::SymbolizeKeys)
      #   test.symbolize_keys # => { abc: 'def' }
      #   test # => { 'abc' => 'def' }
      #
      # @example Nested values are shared, not deep copied
      #   test = { 'abc' => [{ 'def' => 'value' }] }
      #   test.extend(Hashie::Extensions::SymbolizeKeys)
      #   test.symbolize_keys # => { abc: [{ def: 'value' }] }
      #   test # => { 'abc' => [{ def: 'value' }] }
      #
      # @api public
      # @return [Hash] a shallow copy with symbolized keys
      def symbolize_keys
        SymbolizeKeys.symbolize_keys(self)
      end

      # @example Add recursive conversion functions to an object
      #   converter = Object.new.extend(Hashie::Extensions::SymbolizeKeys::ClassMethods)
      #   converter.symbolize_keys('user' => { 'name' => 'Ada' }) # => { user: { name: 'Ada' } }
      module ClassMethods
        # Symbolize all keys recursively within nested
        # hashes and arrays.
        # @api private
        def symbolize_keys_recursively!(object)
          case object
          when ::Array
            object.each do |i|
              symbolize_keys_recursively!(i)
            end
          when ::Hash
            symbolize_keys!(object)
          end
        end

        # Converts keys in a hash recursively to symbols, in place.
        #
        # @example Convert keys through Hashie's module function
        #   test = { 'abc' => 'def' }
        #   Hashie.symbolize_keys!(test)
        #   test # => { abc: 'def' }
        #
        # @api public
        # @param [Hash] hash
        # @return [Hash] the passed hash with symbolized keys
        def symbolize_keys!(hash)
          hash.extend(Hashie::Extensions::SymbolizeKeys) unless hash.respond_to?(:symbolize_keys!)
          hash.keys.each do |k| # rubocop:disable Performance/HashEachMethods
            symbolize_keys_recursively!(hash[k])
            hash[convert_key(k)] = hash.delete(k)
          end
          hash
        end

        # Returns a shallow copy of a hash with recursively symbolized keys.
        # Nested hashes and arrays are shared with the original and are modified.
        #
        # @example Copy keys through Hashie's module function
        #   test = { 'abc' => 'def' }
        #   Hashie.symbolize_keys(test) # => { abc: 'def' }
        #   test # => { 'abc' => 'def' }
        #
        # @api public
        # @param [Hash] hash
        # @return [Hash] a shallow copy with symbolized keys
        def symbolize_keys(hash)
          copy = hash.dup
          copy.extend(Hashie::Extensions::SymbolizeKeys) unless copy.respond_to?(:symbolize_keys!)
          copy.tap do |new_hash|
            symbolize_keys!(new_hash)
          end
        end

        private

        # Converts a key to a symbol, if possible
        #
        # @api private
        # @param [<K>] key the key to attempt convert to a symbol
        # @return [Symbol, K]
        def convert_key(key)
          key.respond_to?(:to_sym) ? key.to_sym : key
        end
      end

      class << self
        include ClassMethods
      end
    end
  end
end
