module Hashie
  module Extensions
    module Mash
      # Overrides the indifferent access of a Mash to keep keys in
      # underscore format.
      #
      # @example
      #   class UnderscoreMash < ::Hashie::Mash
      #     include Hashie::Extensions::Mash::UnderscoreKeys
      #   end
      #
      #   mash = UnderscoreMash.new(symbolKey: { dataFrom: { java: true, javaScript: true } })
      #   mash.symbol_key.data_from.java #=> true
      #   mash.symbolKey.dataFrom.java_script  #=> true
      module UnderscoreKeys
        def self.included(base)
          raise ArgumentError, "#{base} must descent from Hashie::Mash" unless base <= Hashie::Mash
        end

        private

        def _underscore(string)
          string.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
                .gsub(/([a-z\d])([A-Z])/, '\1_\2')
                .tr('- ', '_')
                .downcase
        end

        # Ensures all keys are underscore formatting.
        #
        # @param [Object, String, Symbol] key the key to access.
        # @return [Object] the value assigned to the key.
        def convert_key(key)
          _underscore(key.to_s) if key.is_a?(String) || key.is_a?(Symbol)
        end
      end
    end
  end
end
