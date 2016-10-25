require 'dry-types'

module Hashie
  module Extensions
    module Coercion
      module DryTypes
        module Types
          include Dry::Types.module
        end

        def build_coercion(type)
          if type.respond_to? :call
            lambda do |value|
              return type.call(value)
            end
          else
            fail TypeError, "#{type} is not a coercable type"
          end
        end
      end
    end
  end
end
