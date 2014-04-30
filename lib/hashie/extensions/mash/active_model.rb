module Hashie
  module Extensions
    module Mash
      # Extends Mash to behave in a way compatible with ActiveModel.
      module ActiveModel
        def respond_to?(name, include_private = false)
          return false if name == :permitted?
          super
        end

        def method_missing(name, *args)
          fail ArgumentError if name == :permitted?
          super
        end
      end
    end
  end
end
