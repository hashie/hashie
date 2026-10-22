# frozen_string_literal: true

module Hashie
  module Extensions
    # Initializes a Hash subclass, converting nested hashes to the same class.
    module DeepMergeInitializer
      def initialize(hash = {}, default = nil, &block)
        default.nil? ? super(&block) : super(default)
        hash.each_pair do |key, value|
          self[key] = deep_merge_initializer_value(value, default, &block)
        end
      end

      private

      def deep_merge_initializer_value(value, default, &block)
        case value
        when ::Hash
          self.class.new(value, default, &block)
        when ::Array
          value.map { |item| deep_merge_initializer_value(item, default, &block) }
        else
          value
        end
      end
    end
  end
end
