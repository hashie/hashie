# frozen_string_literal: true

module Hashie
  module Extensions
    # Compatibility extensions for Active Support.
    #
    # @example
    #   require 'active_support/core_ext/hash/except'
    #   require 'hashie/extensions/active_support/core_ext/hash'
    #   klass = Class.new(Hashie::Mash) do
    #     include Hashie::Extensions::ActiveSupport::CoreExt::Hash
    #   end
    #   klass.new(name: 'Ada', age: 37).except(:age).to_h # => {'name' => 'Ada'}
    module ActiveSupport
      # Adapts Active Support core extensions for Hashie objects.
      #
      # @example
      #   require 'active_support/core_ext/hash/except'
      #   require 'hashie/extensions/active_support/core_ext/hash'
      #   klass = Class.new(Hashie::Mash) do
      #     include Hashie::Extensions::ActiveSupport::CoreExt::Hash
      #   end
      #   klass.new(name: 'Ada').except(:name).to_h # => {}
      module CoreExt
        # Converts excluded keys using Mash's key normalization.
        #
        # @example
        #   require 'active_support/core_ext/hash/except'
        #   require 'hashie/extensions/active_support/core_ext/hash'
        #   klass = Class.new(Hashie::Mash) do
        #     include Hashie::Extensions::ActiveSupport::CoreExt::Hash
        #   end
        #   klass.new(name: 'Ada', age: 37).except(:age).to_h # => {'name' => 'Ada'}
        module Hash
          # @example Exclude symbol keys from a string-keyed Mash
          #   require 'active_support/core_ext/hash/except'
          #   require 'hashie/extensions/active_support/core_ext/hash'
          #   klass = Class.new(Hashie::Mash) do
          #     include Hashie::Extensions::ActiveSupport::CoreExt::Hash
          #   end
          #   mash = klass.new(name: 'Ada', age: 37)
          #   mash.except(:age).to_h # => {'name' => 'Ada'}
          #   mash.keys # => ['name', 'age']
          def except(*keys)
            string_keys = keys.map { |key| convert_key(key) }
            super(*string_keys)
          end
        end
      end
    end
  end
end
