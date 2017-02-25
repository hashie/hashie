module Hashie
  module Extensions
    # Extends a Hash to have the ability to convert its keys to strings
    #
    # @example Extend a pre-existing Hash object
    #   hash = { test: 'value' }
    #   hash.extend(Hashie::Extensions::StringifyKeys)
    #   hash.stringify_keys!
    #   hash  #=> { 'test' => 'value' }
    #
    # @example Create a Hash class with this capability
    #   class StringifyingHash < Hash
    #     include Hashie::Extensions::StringifyKeys
    #   end
    #
    #   hash = StringifyingHash.new
    #   hash[:test] = 'value'
    #   hash.stringify_keys!
    #   hash  #=> { 'test' => 'value' }
    #
    # @example Use the module function to stringify keys in a hash
    #   hash = { test: 'value' }
    #   Hashie::Extensions::StringifyKeys.stringify_keys!(hash)
    #   hash  #=> { 'test' => 'value' }
    module StringifyKeys
      # Converts all keys in the hash to strings
      #
      # @example
      #   test = { abc: 'def' }
      #   text.extend(Hashie::Extensions::StringifyKeys)
      #   test.stringify_keys!
      #   test # => { 'abc' => 'def' }
      #
      # @api public
      # @return [Hash] the hash with its keys converted to strings
      def stringify_keys!
        StringifyKeys.stringify_keys!(self)
        self
      end

      # Returns a new hash with all keys converted to strings
      #
      # @example
      #   test = { abc: 'def' }
      #   text.extend(Hashie::Extensions::StringifyKeys)
      #   test.stringify_keys  #=> { 'abc' => 'def' }
      #   test  #=> { abc: 'def' }
      #
      # @api public
      # @return [Hash] a copy of the hash with its keys converted to strings
      def stringify_keys
        StringifyKeys.stringify_keys(self)
      end

      # The methods that will be available on the module itself
      module ClassMethods
        # Stringifies all keys recursively within nested hashes and arrays
        #
        # @api private
        # @param [Object] object
        # @return [Hash] the object with all of its hashes converted to strings
        def stringify_keys_recursively!(object)
          case object
          when self.class
            stringify_keys!(object)
          when ::Array
            object.each do |i|
              stringify_keys_recursively!(i)
            end
          when ::Hash
            stringify_keys!(object)
          end
        end

        # Converts all keys in a Hash to strings
        #
        # @example
        #   test = {abc: 'def'}
        #   Hashie.stringify_keys!(test)
        #   test # => {'abc' => 'def'}
        #
        # @api public
        # @param [Hash] hash
        # @return [Hash] the passed Hash with its keys as strings
        def stringify_keys!(hash)
          hash.extend(Hashie::Extensions::StringifyKeys) unless hash.respond_to?(:stringify_keys!)
          hash.keys.each do |k|
            stringify_keys_recursively!(hash[k])
            hash[k.to_s] = hash.delete(k)
          end
          hash
        end

        # Returns a copy of a Hash with all keys converted to strings
        #
        # @example
        #   test = { abc: 'def' }
        #   Hashie.stringify_keys(test)  #=> { 'abc' => 'def' }
        #   test  #=> { abc: 'def' }
        #
        # @api public
        # @param [::Hash] hash
        # @return [Hash] a copy of the Hash with stringified keys
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
