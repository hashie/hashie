module Hashie
  module Extensions
    module Mash
      # Extends Mash to behave in a way compatible with ActiveModel.
      module ActiveModel
        def respond_to_missing?(method_name, *args)
          return false if method_name == :permitted?
          super
        end

        def method_missing(method_name, *args)
          fail ArgumentError if method_name == :permitted?
          super
        end
      end
    end
  end
end
