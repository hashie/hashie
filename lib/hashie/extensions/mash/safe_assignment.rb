module Hashie
  module Extensions
    module Mash
      module SafeAssignment
        def assign_property(name, value)
          fail ArgumentError, "The property #{name} clashes with an existing method." if methods.include?(name.to_sym)

          self[name] = value
        end
      end
    end
  end
end
