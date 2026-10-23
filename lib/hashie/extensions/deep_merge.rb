module Hashie
  module Extensions
    module DeepMerge
      # Returns a new hash with +self+ and +other_hash+ merged recursively.
      def deep_merge(other_hash, &block)
        copy = _deep_dup(self)
        copy.extend(Hashie::Extensions::DeepMerge) unless copy.respond_to?(:deep_merge!)
        copy.deep_merge!(other_hash, &block)
      end

      # Returns a new hash with +self+ and +other_hash+ merged recursively.
      # Modifies the receiver in place.
      def deep_merge!(other_hash, &block)
        return self unless other_hash.is_a?(::Hash)
        _recursive_merge(self, other_hash, &block)
        self
      end

      # Override to choose an empty destination for an incoming nested hash.
      # Existing destination hashes are merged in place instead.
      def deep_merge_new_hash(_source)
        {}
      end
      protected :deep_merge_new_hash

      # Override to copy or retain a non-Hash value. Calling super uses the
      # supplied default: safe_dup for receiver values, deep_dup (if available)
      # for incoming values. Arrays are passed whole, not traversed here.
      def deep_merge_copy_value(_value)
        yield
      end
      protected :deep_merge_copy_value

      private

      def _deep_dup(hash)
        copy = hash.dup

        copy.each do |key, value|
          copy[key] =
            if value.is_a?(::Hash)
              _deep_dup(value)
            else
              deep_merge_copy_value(value) { Hashie::Utils.safe_dup(value) }
            end
        end

        copy
      end

      def _recursive_merge(hash, other_hash, &block)
        other_hash.each do |k, v|
          hash[k] =
            if hash.key?(k) && hash[k].is_a?(::Hash) && v.is_a?(::Hash)
              _recursive_merge(hash[k], v, &block)
            elsif v.is_a?(::Hash)
              _recursive_merge(deep_merge_new_hash(v), v, &block)
            elsif hash.key?(k) && block_given?
              yield(k, hash[k], v)
            else
              deep_merge_copy_value(v) { v.respond_to?(:deep_dup) ? v.deep_dup : v }
            end
        end
        hash
      end
    end
  end
end
