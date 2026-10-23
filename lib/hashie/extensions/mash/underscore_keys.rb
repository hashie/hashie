# frozen_string_literal: true

require 'hashie/extensions/mash/transform_keys'

module Hashie
  module Extensions
    module Mash
      # Normalizes camel-case and hyphenated Mash keys to lowercase underscores.
      #
      # @example
      #   klass = Class.new(Hashie::Mash) do
      #     include Hashie::Extensions::Mash::UnderscoreKeys
      #   end
      #   klass.new('firstName' => 'Ada', 'last-name' => 'Lovelace').to_h # => {'first_name' => 'Ada', 'last_name' => 'Lovelace'}
      module UnderscoreKeys
        # @example Configure underscore normalization on inclusion
        #   klass = Class.new(Hashie::Mash) do
        #     include Hashie::Extensions::Mash::UnderscoreKeys
        #   end
        #   klass.key_transformer.call('HTTPStatus') # => 'http_status'
        def self.included(base)
          base.include(TransformKeys) unless base < TransformKeys
          base.transform_keys_with do |key|
            key.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
               .gsub(/([a-z\d])([A-Z])/, '\1_\2')
               .tr('-', '_').downcase
          end
        end
      end
    end
  end
end
