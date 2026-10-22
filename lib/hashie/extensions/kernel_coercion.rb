module Hashie
  module Extensions
    module KernelCoercion
      # Core types whose values can be coerced with a stricter
      # +Kernel+ method (e.g. +Kernel#Integer+) instead of the more
      # lenient +#to_i+-style conversion methods used by default.
      #
      # NOTE: There is no strict Kernel method equivalent for +Symbol+, so
      # +Symbol+ coercion is left to the default, lenient +#to_sym+ behavior.
      STRICT_CORE_TYPES = {
        Integer  => :Integer,
        Float    => :Float,
        Complex  => :Complex,
        Rational => :Rational,
        String   => :String
      }.freeze

      # Overrides Hashie::Extensions::Coercion::ClassMethods#build_core_type_coercion
      # to use a stricter Kernel method (e.g. Kernel#Integer) for coercing core
      # types, instead of the default, more lenient conversion method (e.g. #to_i).
      #
      #   "abcd".to_i    #=> 0
      #   Integer("abcd") #=> ArgumentError: invalid value for Integer(): "abcd"
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
