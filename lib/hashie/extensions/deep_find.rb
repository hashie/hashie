module Hashie
  module Extensions
    module DeepFind
      # Performs a depth-first search on deeply nested data structures for
      # a key and returns the first occurrence of the key.
      #
      #  options = {user: {location: {address: '123 Street'}}}
      #  options.deep_find(:address) # => '123 Street'
      def deep_find(key)
        _deep_find(key)
      end

      alias_method :deep_detect, :deep_find

      # Performs a depth-first search on deeply nested data structures for
      # a key and returns all occurrences of the key.
      #
      #  options = {users: [{location: {address: '123 Street'}}, {location: {address: '234 Street'}}]}
      #  options.deep_find_all(:address) # => ['123 Street', '234 Street']
      def deep_find_all(key)
        matches = _deep_find_all(key)
        matches.empty? ? nil : matches
      end

      alias_method :deep_select, :deep_find_all

      private

      def _deep_find(key, object = self)
        if object.respond_to?(:key?)
          return object[key] if object.key?(key)

          reduce_to_match(key, object.values)
        elsif object.is_a?(Enumerable)
          reduce_to_match(key, object)
        end
      end

      def _deep_find_all(key, object = self, matches = [])
        if object.respond_to?(:key?)
          matches << object[key] if object.key?(key)
          object.values.each { |v| _deep_find_all(key, v, matches) }
        elsif object.is_a?(Enumerable)
          object.each { |v| _deep_find_all(key, v, matches) }
        end

        matches
      end

      def reduce_to_match(key, enumerable)
        enumerable.reduce(nil) do |found, value|
          return found if found

          _deep_find(key, value)
        end
      end
    end
  end
end
