# frozen_string_literal: true

module Hashie
  module Extensions
    # Searches nested hashes and arrays for matching string and symbol keys or values.
    module DeepGrep
      def deep_grep(pattern)
        DeepGrep.deep_grep(pattern, self)
      end

      # Returns key/subtree pairs for matching keys, containing hashes for matching
      # scalar values, and matching scalar array elements. Matching keys stop descent.
      def self.deep_grep(pattern, object)
        raise ArgumentError, 'pattern must be a Regexp' unless pattern.is_a?(Regexp)

        search(pattern, object, [], {}.compare_by_identity)
      end

      def self.search(pattern, object, results, ancestors)
        return results if ancestors.key?(object) ||
                          !(object.is_a?(::Hash) || object.is_a?(::Array))

        ancestors[object] = true
        if object.is_a?(::Hash)
          search_hash(pattern, object, results, ancestors)
        else
          search_array(pattern, object, results, ancestors)
        end
        ancestors.delete(object)
        results
      end
      private_class_method :search

      def self.search_hash(pattern, object, results, ancestors)
        results << object if object.any? { |key, value| !matches?(pattern, key) && matches?(pattern, value) }
        object.each do |key, value|
          if matches?(pattern, key)
            results << { key => value }
          else
            search(pattern, value, results, ancestors)
          end
        end
      end
      private_class_method :search_hash

      def self.search_array(pattern, object, results, ancestors)
        object.each do |value|
          matches?(pattern, value) ? results << value : search(pattern, value, results, ancestors)
        end
      end
      private_class_method :search_array

      def self.matches?(pattern, value)
        (value.is_a?(String) || value.is_a?(Symbol)) && pattern.match?(value.to_s)
      end
      private_class_method :matches?
    end
  end
end
