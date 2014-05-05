module Hashie
  module Extensions
    module Dash
      module IndifferentAccess
        def self.included(base)
          base.extend ClassMethods
          base.send :include, Hashie::Extensions::IndifferentAccess
        end

        module ClassMethods
          # Check to see if the specified property has already been
          # defined.
          def property?(name)
            name = name.to_s
            !!properties.find { |property| property.to_s == name }
          end
        end
      end
    end
  end
end
