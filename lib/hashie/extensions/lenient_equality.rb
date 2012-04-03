module Hashie
  module Extensions

    module LenientEquality
      def self.included( base )
        base.class_eval do

          def eql?( other )
            # succeed fast if we're actually equal
            return true if super
            # otherwise, do a deep, lenient comparison
            compare self, other
          end

          protected

          def compare( original, other )
            return false if not original.is_a?( other.class )

            case original
            when Array
              original.reduce( true ) do |memo, a|
                memo && other.reduce( false ) do |memo, b|
                  memo || compare( a, b )
                end
              end
            when ::Hash
              original.reduce( true ) do |memo, (k, v)|
                memo && compare( v, other[ k ] )
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
