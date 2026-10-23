# frozen_string_literal: true

module Hashie
  module Extensions
    # @example Inspect sorted hash entries
    #   class Settings < Hash
    #     include Hashie::Extensions::PrettyInspect
    #   end
    #   hash = Settings[:z, 2, :a, 1]
    #   hash.inspect # => "#<#{Settings} a=1 z=2>"
    module PrettyInspect
      def self.included(base)
        base.send :alias_method, :hash_inspect, :inspect
        base.send :alias_method, :inspect, :hashie_inspect
      end

      # @example Include the class and sorted key/value pairs
      #   class Settings < Hash
      #     include Hashie::Extensions::PrettyInspect
      #   end
      #   hash = Settings[:z, 2, :a, 1]
      #   hash.hashie_inspect # => "#<#{Settings} a=1 z=2>"
      def hashie_inspect
        ret = "#<#{self.class}"
        keys.sort_by(&:to_s).each do |key|
          ret << " #{key}=#{self[key].inspect}"
        end
        ret << '>'
        ret
      end
    end
  end
end
