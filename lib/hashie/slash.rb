module Hashie
  # TODO docs

  class Slash < ::Hash
    def initialize( hash={} )
      merge! hash
    end
  end
end
