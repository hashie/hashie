require 'dry-types'

module Hashie
  module Extensions
    module Coercion
      module DryTypes
        module Types
          include Dry::Types.module
        end

        def self.extended(base)
          base.const_set('Types', Types)
        end

        def build_coercion(type)
          if type.respond_to? :call
            lambda do |value|
              return type.call(value)
            end
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
      end
    end
  end
end
