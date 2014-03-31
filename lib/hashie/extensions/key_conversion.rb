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
        else
          object
        end
      end
    end

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

    module KeyConversion
      def self.included(base)
        base.send :include, SymbolizeKeys
        base.send :include, StringifyKeys
      end
    end
  end
end
