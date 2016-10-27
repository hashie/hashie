require 'active_model/type'

module Hashie
  module Extensions
    module Coercion
      module ActiveModel
        # Symbol is the one glaring type omission. Define it if it is not
        # already defined.
        begin
          ::ActiveModel::Type.lookup(:symbol)
        rescue ArgumentError
          class Symbol < ::ActiveModel::Type::String
            def type
              :symbol
            end

            private

            # The symbol type leverages in coercion logic in the String
            # superclass and simply uses `to_sym` to covert to a symbol.
            def cast_value(value)
              super.to_sym
            end
          end
          ::ActiveModel::Type.register(:symbol, Symbol)
        end

        # Array of symbols of the included ActiveModel types.
        ACTIVE_MODEL_TYPES = ::ActiveModel::Type.registry
                             .send(:registrations)
                             .map { |r| r.send(:name) }
                             .freeze

        def build_coercion(type)
          if type.is_a? Enumerable
            if type.class <= ::Hash
              type, key_type, value_type = type.class, *type.first
              build_hash_coercion(type, key_type, value_type)
            else # Enumerable but not Hash: Array, Set
              value_type = type.first
              type = type.class
              build_container_coercion(type, value_type)
            end
          elsif ACTIVE_MODEL_TYPES.include? type
            build_active_model_type_coercion(type)
          elsif type.respond_to? :coerce
            lambda do |value|
              return value if value.is_a? type
              type.coerce(value)
            end
          elsif type.respond_to? :new
            lambda do |value|
              return value if value.is_a? type
              type.new(value)
            end
          else
            fail TypeError, "#{type} is not a coercable type"
          end
        end

        def build_hash_coercion(type, key_type, value_type)
          key_coerce = fetch_coercion(key_type)
          value_coerce = fetch_coercion(value_type)
          lambda do |value|
            type[value.map { |k, v| [key_coerce.call(k), value_coerce.call(v)] }]
          end
        end

        def build_container_coercion(type, value_type)
          value_coerce = fetch_coercion(value_type)
          lambda do |value|
            type.new(value.map { |v| value_coerce.call(v) })
          end
        end

        def build_active_model_type_coercion(type)
          active_model_type = ::ActiveModel::Type.lookup(type)
          lambda do |value|
            return active_model_type.cast(value)
          end
        end
      end
    end
  end
end
