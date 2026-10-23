# frozen_string_literal: true

module Hashie
  module Extensions
    # Searches nested hashes and arrays for matching string and symbol keys or values.
    #
    # @example Search a nested collection
    #   hash = { people: [{ name: 'Ada' }] }.extend(Hashie::Extensions::DeepGrep)
    #   hash.deep_grep(/Ada/) # => [{ name: 'Ada' }]
    module DeepGrep
      # @example Match a key and return its subtree
      #   hash = { user: { name: 'Ada' } }.extend(Hashie::Extensions::DeepGrep)
      #   hash.deep_grep(/user/) # => [{ user: { name: 'Ada' } }]
      def deep_grep(pattern)
        DeepGrep.deep_grep(pattern, self)
      end

      # Returns key/subtree pairs for matching keys, containing hashes for matching
      # scalar values, and matching scalar array elements. Matching keys stop descent.
      #
      # @example Search an array without extending it
      #   Hashie::Extensions::DeepGrep.deep_grep(/Ada/, ['Ada', 'Grace']) # => ['Ada']
      def self.deep_grep(pattern, object)
        raise ArgumentError, 'pattern must be a Regexp' unless pattern.is_a?(Regexp)

        _search(pattern, object, [], {}.compare_by_identity)
      end

      def self._search(pattern, object, results, ancestors)
        return results if ancestors.key?(object) ||
                          !(object.is_a?(::Hash) || object.is_a?(::Array))

        ancestors[object] = true
        if object.is_a?(::Hash)
          _search_hash(pattern, object, results, ancestors)
        else
          _search_array(pattern, object, results, ancestors)
        end
        ancestors.delete(object)
        results
      end
      private_class_method :_search

      def self._search_hash(pattern, object, results, ancestors)
        results << object if object.any? { |key, value| !_matches?(pattern, key) && _matches?(pattern, value) }
        object.each do |key, value|
          if _matches?(pattern, key)
            results << { key => value }
          else
            _search(pattern, value, results, ancestors)
          end
        end
      end
      private_class_method :_search_hash

      def self._search_array(pattern, object, results, ancestors)
        object.each do |value|
          _matches?(pattern, value) ? results << value : _search(pattern, value, results, ancestors)
        end
      end
      private_class_method :_search_array

      def self._matches?(pattern, value)
        (value.is_a?(String) || value.is_a?(Symbol)) && pattern.match?(value.to_s)
      end
      private_class_method :_matches?
    end
  end
end
