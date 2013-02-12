module Hashie
  module Extensions
    module DeepMerge
      # Returns a new hash with +self+ and +other_hash+ merged recursively.
      def deep_merge(other_hash)
        (class << (h = dup); self; end).send :include, Hashie::Extensions::DeepMerge
        h.deep_merge!(other_hash)
      end

      # Returns a new hash with +self+ and +other_hash+ merged recursively.
      # Modifies the receiver in place.
      def deep_merge!(other_hash)
        other_hash.each do |k,v|
          (class << (tv = self[k]); self; end).send :include, Hashie::Extensions::DeepMerge
          self[k] = tv.is_a?(::Hash) && v.is_a?(::Hash) ? tv.deep_merge(v) : v
        end
        self
      end
    end
  end
end
