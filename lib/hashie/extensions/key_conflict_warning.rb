module Hashie
  module Extensions
    module KeyConflictWarning
      class CannotDisableMashWarnings < StandardError
        def initialize
          super(
            'You cannot disable warnings on the base Mash class. ' \
            'Please subclass the Mash and disable it in the subclass.'
          )
        end
      end

      # Disable the logging of warnings based on keys conflicting keys/methods
      #
      # @api semipublic
      # @return [void]
      def disable_warnings(*method_keys)
        raise CannotDisableMashWarnings if self == Hashie::Mash
        if method_keys.any?
          disable_warnings_blacklist.concat(method_keys).tap(&:flatten!).uniq!
        else
          disable_warnings_blacklist.clear
        end

        @disable_warnings = true
      end

      # Checks whether this class disables warnings for conflicting keys/methods
      #
      # @api semipublic
      # @return [Boolean]
      def disable_warnings?(method_key = nil)
        return disable_warnings_blacklist.include?(method_key) if disable_warnings_blacklist.any? && method_key
        @disable_warnings ||= false
      end

      # Returns an array of blacklisted methods that this class disables warnings for.
      #
      # @api semipublic
      # @return [Boolean]
      def disable_warnings_blacklist
        @_disable_warnings_blacklist ||= []
      end

      # Inheritance hook that sets class configuration when inherited.
      #
      # @api semipublic
      # @return [void]
      def inherited(subclass)
        super
        subclass.disable_warnings(disable_warnings_blacklist) if disable_warnings?
      end
    end
  end
end
