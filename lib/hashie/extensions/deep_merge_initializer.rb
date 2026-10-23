# frozen_string_literal: true

module Hashie
  module Extensions
    # Initializes a Hash subclass, converting nested hashes to the same class.
    #
    # @example Initialize nested hash instances
    #   class NestedHash < Hash
    #     include Hashie::Extensions::DeepMergeInitializer
    #   end
    #   hash = NestedHash.new(user: { name: 'Ada' })
    #   hash[:user].class # => NestedHash
    module DeepMergeInitializer
      # @example Convert hashes inside arrays and retain a default
      #   class NestedHash < Hash
      #     include Hashie::Extensions::DeepMergeInitializer
      #   end
      #   hash = NestedHash.new({ users: [{ name: 'Ada' }] }, false)
      #   hash[:users].first.class # => NestedHash
      #   hash[:users].first[:missing] # => false
      def initialize(hash = {}, default = nil, &block)
        default.nil? ? super(&block) : super(default)
        hash.each_pair do |key, value|
          self[key] = _deep_merge_initializer_value(value, default, &block)
        end
      end

      private

      def _deep_merge_initializer_value(value, default, &block)
        case value
        when ::Hash
          self.class.new(value, default, &block)
        when ::Array
          value.map { |item| _deep_merge_initializer_value(item, default, &block) }
        else
          value
        end
      end
    end
  end
end
