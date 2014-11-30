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
        _symbolize_keys!(self)
        self
      end

      # Return a new hash with all keys converted
      # to symbols.
      def symbolize_keys
        dup.symbolize_keys!
      end

      protected

      # Symbolize all keys recursively within nested
      # hashes and arrays.
      def _symbolize_keys_recursively!(object)
        case object
        when self.class
          object.symbolize_keys!
        when ::Array
          object.each do |i|
            _symbolize_keys_recursively!(i)
          end
        when ::Hash
          _symbolize_keys!(object)
        end
      end

      def _symbolize_keys!(hash)
        hash.keys.each do |k|
          _symbolize_keys_recursively!(hash[k])
          hash[k.to_sym] = hash.delete(k)
        end
      end
    end
  end
end
