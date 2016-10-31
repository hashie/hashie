module Hashie
  module Extensions
    module Dash
      module Coercion
        includer = ::Hashie::Extensions::Coercion::CoercionSystemIncludeBuilder
                   .new do |base|
          # Extends a Dash with the ability to define coercion for properties.
          common = Hashie::Extensions::Coercion::Includer.common_included_block
          instance_exec(base, &common)
          base.extend ClassMethods
        end
        extend includer

        module ClassMethods
          # Defines a property on the Dash. Options are the standard
          # <tt>Hashie::Dash#property</tt> options plus:
          #
          # * <tt>:coerce</tt> - The class into which you want the property coerced.
          def property(property_name, options = {})
            super
            coerce_key property_name, options[:coerce] if options[:coerce]
          end
        end
      end
    end
  end
end
