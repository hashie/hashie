module Hashie
  # TODO docs

  class Slash < ::Hash
    def initialize( hash={} )
      merge! hash
    end

    def eql?( other )
      # succeed fast if we're actually equal
      return true if super

      walk other do |key, value|
        # we must have every key from the other hash,
        # not the other way around
        return false if not has_key? key

        # decide how to determine "equality" based on the key's class
        case value
        when Array
          self[ key ].sort == value.sort
        when Hash
          walk value
        else
          self[ key ] == value
        end
      end
    end

    protected

    def walk( hsh, &block )
      hsh.reduce true do |memo, (k, v)|
        block.call( k, v ) and memo
      end
    end
  end
end
