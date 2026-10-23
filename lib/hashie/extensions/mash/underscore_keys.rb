# frozen_string_literal: true

require 'hashie/extensions/mash/transform_keys'

module Hashie
  module Extensions
    module Mash
      # Normalizes camel-case and hyphenated Mash keys to lowercase underscores.
      module UnderscoreKeys
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
