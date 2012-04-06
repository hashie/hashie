module Hashie
  module Extensions
    # LenientEquality alters the behavior of your hash's
    # #eql? method to make it much more lenient during
    # hash comparison.
    #
    # A lenient hash will eql another hash if the lenient
    # hash is a subset of the other hash. This is useful,
    # for instance, when testing APIs where you only want
    # to test for the presence of keys that you care about.
    #
    # Lenient equality also considers the order of all
    # hashes and arrays in the hash structure unimportant.
    # Two arrays will be considered equal if they have the
    # same entries, but in any order.
    #
    # All lenient comparison works for deeply-nested
    # structures as well.
    #
    # @example
    #   class MyHash < Hash
    #     include Hashie::Extensions::MergeInitializer
    #     include Hashie::Extensions::LenientEquality
    #   end
    #
    #   h = MyHash.new(:foo => [1, 2, 3])
    #   h.eql? {:foo => [1, 2, 3], :bar => 'baz'} # => true
    #   h.eql? {:foo => [3, 2, 1]}                # => true
    #   h.eql? {:baz => [1, 2, 3]}                # => false
    #
    module LenientEquality
      def self.included(base)
        base.class_eval do

          # To be lenient, we override the #eql? method,
          # first checking if we're truly equal, but
          # falling back to our lenient comparison.
          def eql?(other)
            # succeed fast if we're actually equal
            return true if super
            # otherwise, do a deep, lenient comparison
            lenient_compare self, other
          end

          protected

          def lenient_compare(original, other)
            return false if not original.is_a?(other.class)

            case original
            when Array
              original.reduce(true) do |memo, a|
                memo && other.reduce(false) do |memo, b|
                  memo || lenient_compare(a, b)
                end
              end
            when ::Hash
              original.reduce(true) do |memo, (k, v)|
                memo && lenient_compare(v, other[k])
              end
            else
              original == other
            end
          end
        end
      end
    end
  end
end
