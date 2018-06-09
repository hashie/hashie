module Hashie
  module Extensions
    # Extends a Hash to have the ability to symbolize its keys
    #
    # @example Extend a pre-existing Hash object
    #   hash = { 'test' => 'value' }
    #   hash.extend(Hashie::Extensions::SymbolizeKeys)
    #   hash.symbolize_keys!
    #   hash  #=> { test: 'value' }
    #
    # @example Create a Hash class with this capability
    #   class SymbolizableHash < Hash
    #     include Hashie::Extensions::SymbolizeKeys
    #   end
    #
    #   hash = SymbolizableHash.new
    #   hash['test'] = 'value'
    #   hash.symbolize_keys!
    #   hash  #=> { test: 'value' }
    #
    # @example Use the module function to symbolize keys in a hash
    #   hash = { 'test' => 'value' }
    #   Hashie::Extensions::SymbolizeKeys.symbolize_keys!(hash)
    #   hash  #=> { test: 'value' }
    module SymbolizeKeys
      # Converts all keys in the hash to symbols
      #
      # @example
      #   test = { 'abc' => 'def' }
      #   test.extend(Hashie::Extensions::SymbolizeKeys)
      #   test.symbolize_keys!
      #   test # => { abc: 'def' }
      #
      # @api public
      # @return [Hash] the hash with its keys symbolized
      def symbolize_keys!
        SymbolizeKeys.symbolize_keys!(self)
        self
      end

      # Returns a new hash with all keys converted to symbols
      #
      # @example
      #   test = { 'abc' => 'def' }
      #   test.extend(Hashie::Extensions::SymbolizeKeys)
      #   test.symbolize_keys  #=> { abc: 'def' }
      #   test  #=> { 'abc' => 'def' }
      #
      # @api public
      # @return [Hash] a copy of the hash with symbolized keys
      def symbolize_keys
        SymbolizeKeys.symbolize_keys(self)
      end

      # The methods that will be available on the module itself
      module ClassMethods
        # Symbolizes all keys recursively within nested hashes and arrays
        #
        # @api private
        # @param [Object] object
        # @return [Hash] the object with all of its hashes symbolized
        def symbolize_keys_recursively!(object)
          case object
          when self.class
            symbolize_keys!(object)
          when ::Array
            object.each do |i|
              symbolize_keys_recursively!(i)
            end
          when ::Hash
            symbolize_keys!(object)
          end
        end

        # Converts all keys in a Hash to symbols
        #
        # @example
        #   test = {'abc' => 'def'}
        #   Hashie.symbolize_keys!(test)
        #   test # => {abc: 'def'}
        #
        # @api public
        # @param [Hash] hash
        # @return [Hash] the passed hash with its keys as symbols
        def symbolize_keys!(hash)
          hash.extend(Hashie::Extensions::SymbolizeKeys) unless hash.respond_to?(:symbolize_keys!)
          hash.keys.each do |k|
            symbolize_keys_recursively!(hash[k])
            hash[k.to_sym] = hash.delete(k)
          end
          hash
        end

        # Returns a copy of a Hash with all keys converted to symbols
        #
        # @example
        #   test = { 'abc' => 'def' }
        #   Hashie.symbolize_keys(test)  #=> { abc: 'def' }
        #   test  #=> { 'abc' => 'def' }
        #
        # @api public
        # @param [::Hash] hash
        # @return [Hash] a copy of the hash with symbolized keys
        def symbolize_keys(hash)
          copy = hash.dup
          copy.extend(Hashie::Extensions::SymbolizeKeys) unless copy.respond_to?(:symbolize_keys!)
          copy.tap do |new_hash|
            symbolize_keys!(new_hash)
          end
        end
      end

      class << self
        include ClassMethods
      end
    end
  end
end
