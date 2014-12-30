module Hashie
  module Extensions
    module SymbolizeKeys
      # Convert all keys in the hash to symbols.
      #
      # @example
      #   test = {'abc' => 'def'}
      #   test.symbolize_keys!
      #   test # => {:abc => 'def'}
      def symbolize_keys!
        SymbolizeKeys.symbolize_keys!(self)
        self
      end

      # Return a new hash with all keys converted
      # to symbols.
      def symbolize_keys
        dup.symbolize_keys!
      end

      module ClassMethods
        # Symbolize all keys recursively within nested
        # hashes and arrays.
        # @api private
        def symbolize_keys_recursively!(object)
          object.symbolize_keys! if object.respond_to? :symbolize_keys!

          case object
          when ::Array
            object.each do |i|
              symbolize_keys_recursively!(i)
            end
          when ::Hash
            symbolize_keys!(object)
          end
        end

        # Convert all keys in hash to symbols.
        #
        # @param [Hash] hash
        # @example
        #   test = {'abc' => 'def'}
        #   Hashie.symbolize_keys! test
        #   test # => {:abc => 'def'}
        def symbolize_keys!(hash)
          hash.keys.each do |k|
            symbolize_keys_recursively!(hash[k])
            hash[k.to_sym] = hash.delete(k)
          end
          hash
        end

        # Return a copy of hash with all keys converted
        # to symbols.
        # @param [::Hash] hash
        def symbolize_keys(hash)
          hash.dup.tap do | new_hash |
            symbolize_keys! new_hash
          end
        end
      end

      class << self
        include ClassMethods
      end
    end
  end
end
