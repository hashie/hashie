# frozen_string_literal: true

module Hashie
  module Extensions
    # @example Include both key conversion extensions
    #   class ConvertibleHash < Hash
    #     include Hashie::Extensions::KeyConversion
    #   end
    #   hash = ConvertibleHash[:name, 'Ada']
    #   hash.stringify_keys # => { 'name' => 'Ada' }
    #   hash.stringify_keys!.symbolize_keys # => { name: 'Ada' }
    module KeyConversion
      def self.included(base)
        base.send :include, SymbolizeKeys
        base.send :include, StringifyKeys
      end
    end
  end
end
