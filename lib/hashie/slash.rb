module Hashie
  # TODO docs

  class Slash < ::Hash
    def initialize( hash={} )
      merge! hash
    end

    def walk( hsh, &block )
      hsh.each do |k, v|
        # next unless
        block.call v.class, k, v
      end
    end

    def eql?( other )
      # succeed fast if we're actually equal
      return true if super

      walk other do |type, key, value|
        case type
        when Array
          self[ key ].sort == value.sort
        when Hash
          walk value
        else
          self[ key ] == value
        end
      end
    end
  end
end
