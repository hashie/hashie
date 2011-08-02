module Hashie
  module Extensions
    # The MergeInitializer is a super-simple mixin that allows
    # you to initialize a subclass of Hash with another Hash
    # to give you faster startup time for Hash subclasses. Note
    # that you can still provide a default value as a second
    # argument to the initializer.
    #
    # @example
    #   class MyHash < Hash
    #     include Hashie::Extensions::MergeInitializer
    #   end
    #
    #   h = MyHash.new(:abc => 'def')
    #   h[:abc] # => 'def'
    #
    module MergeInitializer
      def initialize(hash = {}, default = nil, &block)
        super(default, &block)
        update(hash)
      end
    end
  end
end
