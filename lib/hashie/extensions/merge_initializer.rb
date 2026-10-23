# frozen_string_literal: true

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
      # @example Initialize entries and a default value
      #   class InitializedHash < Hash
      #     include Hashie::Extensions::MergeInitializer
      #   end
      #   hash = InitializedHash.new({ name: 'Ada' }, 'unknown')
      #   hash[:name] # => 'Ada'
      #   hash[:missing] # => 'unknown'
      def initialize(hash = {}, default = nil, &block)
        default ? super(default) : super(&block)
        hash.each do |key, value|
          self[key] = value
        end
      end
    end
  end
end
