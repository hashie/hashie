module Hashie
  # TODO docs

  class Slash < ::Hash
    def initialize( hash={} )
      merge! hash
    end

    def eql?( other )
      # succeed fast if we're actually equal
      return true if super
      # otherwise, do a deep, lenient comparison
      compare self, other
    end

    protected

    def compare( original, other )
      case other
      when Array
        original.reduce true do |memo, a|
          memo and other.reduce false do |memo, b|
            memo or compare a, b
          end
        end
      when ::Hash
        original.reduce true do |memo, (k, v)|
          memo and compare v, other[ k ]
        end
      else
        original.eql? other
      end
    end
  end
end
