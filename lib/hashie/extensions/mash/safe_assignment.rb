module Hashie
  module Extensions
    module Mash
      module SafeAssignment
        def custom_writer(key, *args) #:nodoc:
          fail ArgumentError, "The property #{key} clashes with an existing method." if methods.include?(key.to_sym)
          super
        end

        def []=(*args)
          custom_writer(*args)
        end
      end
    end
  end
end
