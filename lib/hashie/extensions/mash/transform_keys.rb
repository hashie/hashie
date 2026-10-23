# frozen_string_literal: true

module Hashie
  module Extensions
    module Mash
      # Applies a class-configured normalization to string and symbol Mash keys.
      module TransformKeys
        def self.included(base)
          raise ArgumentError, "`#{base}` must descend from Hashie::Mash" unless base <= Hashie::Mash

          base.extend(ClassMethods)
        end

        # Configures key normalization independently for each subclass.
        module ClassMethods
          def inherited(klass)
            super
            klass.instance_variable_set(:@key_transformer, key_transformer)
          end

          def transform_keys_with(callable = nil, &block)
            raise ArgumentError, 'provide one callable or block' if (callable && block) || !(callable || block).respond_to?(:call)

            @key_transformer = callable || block
          end

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
