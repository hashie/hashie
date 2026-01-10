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
        ACRONYMS = {}

        def self.included(base)
          raise ArgumentError, "#{base} must descent from Hashie::Mash" unless base <= Hashie::Mash
        end

        private

        # Makes an underscored, lowercase form from the expression in the string.
        # Also converts spaces and colons to underscore
        #
        # @param [String, Symbol] camel_cased_word to be pocessed
        # @return [String] underscored string
        def _underscore(camel_cased_word)
          # check if there is work to be done, if not early exit
          return camel_cased_word.to_s unless /[A-Z\-: ]/.match?(camel_cased_word)

          acronym_regex = ACRONYMS.empty? ? /(?=a)b/ : /#{ACRONYMS.values.join("|")}/
          acronyms_underscore_regex = /(?:(?<=([A-Za-z\d]))|\b)(#{acronym_regex})(?=\b|[^a-z])/

          word = camel_cased_word.gsub(acronyms_underscore_regex) do
            "#{::Regexp.last_match(1) && '_'}#{::Regexp.last_match(2).downcase}"
          end

          word.gsub!(/([A-Z]+)(?=[A-Z][a-z])|([a-z\d])(?=[A-Z])/) do
            (::Regexp.last_match(1) || ::Regexp.last_match(2)) << '_'
          end

          word.tr!('- ', '_')
          word.downcase!
          word
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
