module Hashie
  module Extensions
    # Marker module to indicate has a single-argument hash constructor.
    module HashInitializer
    end

    # Doesn't work...
    # module MergeInitializer
    # include HashInitializer
    # end
  end

  class Hash
    # Not unless MergeInititalizer is included
  end

  class Mash
    include Extensions::HashInitializer
  end

  class Dash
    include Extensions::HashInitializer
  end
end
