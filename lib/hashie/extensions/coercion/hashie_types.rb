module Hashie
  module Extensions
    module Coercion
      module HashieTypes
        CORE_TYPES = {
          Integer    => :to_i,
          Float      => :to_f,
          Complex    => :to_c,
          Rational   => :to_r,
          String     => :to_s,
          Symbol     => :to_sym
        }

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
          elsif CORE_TYPES.key? type
            build_core_type_coercion(type)
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

        def build_core_type_coercion(type)
          name = CORE_TYPES[type]
          lambda do |value|
            return value if value.is_a? type
            return value.send(name)
          end
        end
      end
    end
  end
end
