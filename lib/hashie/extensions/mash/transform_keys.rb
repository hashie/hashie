# frozen_string_literal: true

module Hashie
  module Extensions
    module Mash
      # Applies a class-configured normalization to string and symbol Mash keys.
      #
      # @example
      #   klass = Class.new(Hashie::Mash) do
      #     include Hashie::Extensions::Mash::TransformKeys
      #     transform_keys_with(&:downcase)
      #   end
      #   klass.new('NAME' => 'Ada').name # => 'Ada'
      module TransformKeys
        # @example Install class-level transformation configuration
        #   klass = Class.new(Hashie::Mash) do
        #     include Hashie::Extensions::Mash::TransformKeys
        #   end
        #   klass.key_transformer # => nil
        def self.included(base)
          raise ArgumentError, "`#{base}` must descend from Hashie::Mash" unless base <= Hashie::Mash

          base.extend(ClassMethods)
        end

        # Configures key normalization independently for each subclass.
        #
        # @example
        #   klass = Class.new(Hashie::Mash) do
        #     include Hashie::Extensions::Mash::TransformKeys
        #     transform_keys_with(&:downcase)
        #   end
        #   klass.new('NAME' => 'Ada')['name'] # => 'Ada'
        module ClassMethods
          # @example Inherit a transformer without sharing later configuration
          #   parent = Class.new(Hashie::Mash) do
          #     include Hashie::Extensions::Mash::TransformKeys
          #     transform_keys_with(&:downcase)
          #   end
          #   child = Class.new(parent)
          #   child.new('NAME' => 'Ada').name # => 'Ada'
          #   child.transform_keys_with(&:upcase)
          #   parent.new('NAME' => 'Ada').keys # => ['name']
          def inherited(klass)
            super
            klass.instance_variable_set(:@key_transformer, key_transformer)
          end

          # @example Configure with a callable or a block
          #   klass = Class.new(Hashie::Mash) do
          #     include Hashie::Extensions::Mash::TransformKeys
          #     transform_keys_with(->(key) { key.downcase })
          #   end
          #   klass.new('NAME' => 'Ada').keys # => ['name']
          #   klass.transform_keys_with { |key| key.upcase }
          #   klass.new(name: 'Ada').keys # => ['NAME']
          def transform_keys_with(callable = nil, &block)
            raise ArgumentError, 'provide one callable or block' if (callable && block) || !(callable || block).respond_to?(:call)

            @key_transformer = callable || block
          end

          # @example Read the configured callable
          #   klass = Class.new(Hashie::Mash) do
          #     include Hashie::Extensions::Mash::TransformKeys
          #     transform_keys_with(&:downcase)
          #   end
          #   klass.key_transformer.call('NAME') # => 'name'
          attr_reader :key_transformer
        end

        private

        def convert_key(key)
          transformer = self.class.key_transformer
          return super unless transformer && (key.is_a?(String) || key.is_a?(Symbol))

          transformed = transformer.call(key.to_s)
          raise TypeError, 'key transformer must return a String' unless transformed.is_a?(String)

          super(transformed)
        end
      end
    end
  end
end
