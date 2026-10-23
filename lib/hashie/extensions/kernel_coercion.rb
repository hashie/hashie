# frozen_string_literal: true

module Hashie
  module Extensions
    # @example Opt in to strict numeric coercion
    #   klass = Class.new(Hash) do
    #     include Hashie::Extensions::Coercion
    #     extend Hashie::Extensions::KernelCoercion
    #     coerce_key :age, Integer
    #   end
    #   hash = klass.new
    #   hash[:age] = '42'
    #   hash[:age] # => 42
    #   expect { hash[:age] = 'bad' }.to raise_error(Hashie::CoercionError)
    module KernelCoercion
      # Core types whose values can be coerced with a stricter
      # +Kernel+ method (e.g. +Kernel#Integer+) instead of the more
      # lenient +#to_i+-style conversion methods used by default.
      #
      # NOTE: There is no strict Kernel method equivalent for +Symbol+, so
      # +Symbol+ coercion is left to the default, lenient +#to_sym+ behavior.
      STRICT_CORE_TYPES = {
        Integer => :Integer,
        Float => :Float,
        Complex => :Complex,
        Rational => :Rational,
        String => :String
      }.freeze

      # Overrides Hashie::Extensions::Coercion::ClassMethods#build_core_type_coercion
      # to use a stricter Kernel method (e.g. Kernel#Integer) for coercing core
      # types, instead of the default, more lenient conversion method (e.g. #to_i).
      #
      #   "abcd".to_i    #=> 0
      #   Integer("abcd") #=> ArgumentError: invalid value for Integer(): "abcd"
      #
      # @example Build a strict conversion and preserve Symbol fallback
      #   klass = Class.new(Hash) do
      #     include Hashie::Extensions::Coercion
      #     extend Hashie::Extensions::KernelCoercion
      #   end
      #   conversion = klass.build_core_type_coercion(Integer)
      #   conversion.call('42') # => 42
      #   expect { conversion.call('42 items') }.to raise_error(ArgumentError)
      #   klass.build_core_type_coercion(Symbol).call('name') # => :name
      def build_core_type_coercion(type)
        return super unless STRICT_CORE_TYPES.key?(type)

        kernel_method = STRICT_CORE_TYPES[type]
        lambda do |value|
          next value if value.is_a?(type)

          Kernel.public_send(kernel_method, value)
        end
      end
    end
  end
end
