module Hashie
  module Extensions
    module DeepMerge
      # Returns a new hash with +self+ and +other_hash+ merged recursively.
      def deep_merge(other_hash)
        dup.deep_merge!(other_hash)
      end

      # Returns a new hash with +self+ and +other_hash+ merged recursively.
      # Modifies the receiver in place.
      def deep_merge!(other_hash)
        _recursive_merge(self, other_hash)
        self
      end

      private

      def _recursive_merge(hash, other_hash)
        if other_hash.is_a?(::Hash) && hash.is_a?(::Hash)
          other_hash.each do |k, v|
            hash[k] = hash.key?(k) ? _recursive_merge(hash[k], v) : v
          end
          hash
        else
          other_hash
        end
      end
    end
  end
end
