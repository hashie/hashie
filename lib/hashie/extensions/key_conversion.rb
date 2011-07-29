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
          self[k.to_s] = self.delete(k)
        end
        self
      end

      # Return a new hash with all keys converted
      # to strings.
      def stringify_keys
        dup.stringify_keys!
      end
    end

    module SymbolizeKeys
      # Convert all keys in the hash to strings.
      #
      # @example
      #   test = {'abc' => 'def'}
      #   test.symbolize_keys!
      #   test # => {:abc => 'def'}
      def symbolize_keys!
        keys.each do |k|
          self[k.to_sym] = self.delete(k)
        end
        self
      end

      # Return a new hash with all keys converted
      # to symbols.
      def symbolize_keys
        dup.symbolize_keys!
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
