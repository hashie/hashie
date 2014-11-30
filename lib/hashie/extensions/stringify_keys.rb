module Hashie
  module Extensions
    module StringifyKeys
      # Convert all keys in the hash to strings.
      #
      # @example
      #   test = {:abc => 'def'}
      #   test.stringify_keys!
      #   test # => {'abc' => 'def'}
      def stringify_keys!
        _stringify_keys!(self)
        self
      end

      # Return a new hash with all keys converted
      # to strings.
      def stringify_keys
        dup.stringify_keys!
      end

      protected

      # Stringify all keys recursively within nested
      # hashes and arrays.
      def _stringify_keys_recursively!(object)
        case object
        when self.class
          object.stringify_keys!
        when ::Array
          object.each do |i|
            _stringify_keys_recursively!(i)
          end
        when ::Hash
          _stringify_keys!(object)
        end
      end

      def _stringify_keys!(hash)
        hash.keys.each do |k|
          _stringify_keys_recursively!(hash[k])
          hash[k.to_s] = hash.delete(k)
        end
      end
    end
  end
end
