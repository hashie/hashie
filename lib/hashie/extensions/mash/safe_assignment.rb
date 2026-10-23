# frozen_string_literal: true

module Hashie
  module Extensions
    module Mash
      module SafeAssignment
        def custom_writer(key, *args) # :nodoc:
          raise ArgumentError, "the property `#{key}` clashes with an existing method" if !key?(key) && respond_to?(key, true)

          super
        end

        def []=(*args)
          custom_writer(*args)
        end
      end
    end
  end
end
