module Hashie
  module Extensions
    module Mash
      # Overrides Mash's default behavior of returning nil for keys that
      # aren't set, raising a KeyError instead.
      #
      # Unlike Hashie::Extensions::StrictKeyAccess, this extension is aware
      # of Mash's special suffixed methods (e.g. +?+, +!+, +_+ and +=+) so
      # that they continue to work as expected instead of always raising.
      #
      # Because nested Hashes are converted into instances of +self.class+,
      # this extension is automatically applied to any nested Mash as well.
      #
      # @example
      #   class StrictMash < Hashie::Mash
      #     include Hashie::Extensions::Mash::StrictKeyAccess
      #   end
      #
      #   mash = StrictMash.new(name: 'Bob')
      #   mash.name  #=> 'Bob'
      #   mash.age   #=> KeyError: key not found: "age"
      #
      #   mash.name? #=> true
      #   mash.age?  #=> false
      #
      #   mash.address!.city = 'Springfield'
      #   mash.address.city  #=> 'Springfield'
      #
      # @api public
      module StrictKeyAccess
        # Hook for being included in a class
        #
        # @api private
        # @return [void]
        # @raise [ArgumentError] when the base class isn't a Mash
        def self.included(descendant)
          error_message = "#{descendant} is not a kind of Hashie::Mash"
          raise ArgumentError, error_message unless descendant <= Hashie::Mash
        end

        # @api private
        def method_missing(method_name, *args, &blk)
          return super if key?(method_name)

          name, suffix = method_name_and_suffix(method_name)
          raise KeyError, "key not found: #{name.inspect}" if !key?(name) && !suffix

          super
        end

        # @api private
        def respond_to_missing?(method_name, *args)
          return true if key?(method_name)

          _, suffix = method_name_and_suffix(method_name)
          return false unless suffix

          super
        end
      end
    end
  end
end
