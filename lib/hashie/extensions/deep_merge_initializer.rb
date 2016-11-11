module Hashie
  module Extensions
    # The DeepMergeInitializer is a super-simple mixin that allows
    # you to initialize a subclass of Hash with another Hash
    # to give you faster startup time for Hash subclasses.
    # It's almost the same as MergeInitializer but nested hashes
    # are same type as main object. Note
    # that you can still provide a default value as a second
    # argument to the initializer.
    #
    # @example
    #   class MyHash < Hash
    #     include Hashie::Extensions::DeepMergeInitializer
    #   end
    #
    #   h = MyHash.new(abc: 'def', hashy: { abc: 'def' })
    #   h[:abc] # => 'def'
    #   h[:hashy].class # => MyHash
    #
    module DeepMergeInitializer
      def self.included(base)
        base.class_eval do
          def initialize(hash = {}, default = nil, &block)
            default ? super(default) : super(&block)
            hash.each do |key, value|
              self[key] = if value.is_a?(::Hash)
                            self.class.new(value, default, &block)
                          else
                            value
                          end
            end
          end
        end
      end
    end
  end
end
