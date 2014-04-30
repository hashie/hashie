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
        keys.each do |k|
          symbolize_keys_recursively!(self[k])
          self[k.to_sym] = delete(k)
        end
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
      def symbolize_keys_recursively!(object)
        if self.class === object
          object.symbolize_keys!
        elsif ::Array === object
          object.each do |i|
            symbolize_keys_recursively!(i)
          end
          object
        elsif object.respond_to?(:symbolize_keys!)
          object.symbolize_keys!
        else
          object
        end
      end
    end
  end
end
