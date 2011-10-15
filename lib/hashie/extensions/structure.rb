module Hashie
  module Extensions
    # The Structure extension provides facilities for declaring
    # properties that a Hash can have. This provides for the
    # creation of structures that still behave like hashes but
    # do not allow setting non-allowed keys.
    #
    # @example
    #   class RestrictedHash < Hash
    #     include Hashie::Extensions::MergeInitializer
    #     include Hashie::Extensions::Structure
    #
    #     key :first
    #     key :second, :default => 'foo'
    #   end
    #
    #   h = RestrictedHash.new(:first => 1)
    #   h[:first]  # => 1
    #   h[:second] # => 'foo'
    #   h[:third]  # => ArgumentError
    #
    module Structure
      def self.included(base)
        base.extend ClassMethods
        base.class_eval do
          @permitted_keys = superclass.permitted_keys if superclass.respond_to?(:permitted_keys)
        end
      end

      module ClassMethods
        def key(key, options = {})
          (@permitted_keys ||= []) << key

          if options[:default]
            (@default_values ||= {})[key] = options.delete(:default)
          end

          permitted_keys
        end

        def permitted_keys
          @permitted_keys
        end
      end
    end
  end
end
