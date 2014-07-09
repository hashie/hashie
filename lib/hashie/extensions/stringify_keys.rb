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
        keys.each do |k|
          stringify_keys_recursively!(self[k])
          self[k.to_s] = delete(k)
        end
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
      def stringify_keys_recursively!(object)
        if self.class === object
          object.stringify_keys!
        elsif ::Array === object
          object.each do |i|
            stringify_keys_recursively!(i)
          end
          object
        elsif object.respond_to?(:stringify_keys!)
          object.stringify_keys!
        elsif ::Hash === object
          object.keys.each do |k|
            stringify_keys_recursively!(object[k])
            object[k.to_s] = object.delete(k)
          end
          object
        else
          object
        end
      end
    end
  end
end
