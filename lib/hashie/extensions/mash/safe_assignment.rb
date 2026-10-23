# frozen_string_literal: true

module Hashie
  module Extensions
    module Mash
      # Rejects assignments that would shadow existing Mash methods.
      #
      # @example
      #   klass = Class.new(Hashie::Mash) do
      #     include Hashie::Extensions::Mash::SafeAssignment
      #   end
      #   mash = klass.new
      #   expect { mash[:size] = 2 }.to raise_error(ArgumentError, /clashes/)
      #   mash.empty? # => true
      module SafeAssignment
        def custom_writer(key, *args) # :nodoc:
          raise ArgumentError, "the property `#{key}` clashes with an existing method" if !key?(key) && respond_to?(key, true)

          super
        end

        # @example
        #   klass = Class.new(Hashie::Mash) do
        #     include Hashie::Extensions::Mash::SafeAssignment
        #   end
        #   mash = klass.new
        #   mash[:name] = 'Ada'
        #   mash.name # => 'Ada'
        #   expect { mash[:size] = 2 }.to raise_error(ArgumentError, /clashes/)
        def []=(*args)
          custom_writer(*args)
        end
      end
    end
  end
end
