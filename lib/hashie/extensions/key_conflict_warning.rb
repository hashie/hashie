# frozen_string_literal: true

module Hashie
  module Extensions
    # @example Disable conflict warnings on a Mash subclass
    #   klass = Class.new(Hashie::Mash)
    #   klass.disable_warnings(:size)
    #   klass.disable_warnings?(:size) # => true
    #   klass.disable_warnings?(:keys) # => false
    module KeyConflictWarning
      # @example Explain why base Mash warnings cannot be disabled
      #   require 'hashie/mash'
      #   error = Hashie::Extensions::KeyConflictWarning::CannotDisableMashWarnings.new
      #   error.message.include?('please subclass the Mash') # => true
      class CannotDisableMashWarnings < StandardError
        # @example Construct the warning configuration error
        #   require 'hashie/mash'
        #   error = Hashie::Extensions::KeyConflictWarning::CannotDisableMashWarnings.new
        #   error.message # => 'you cannot disable warnings on the base Mash class; please subclass the Mash and disable it in the subclass'
        def initialize
          super(
            'you cannot disable warnings on the base Mash class; ' \
            'please subclass the Mash and disable it in the subclass'
          )
        end
      end

      # Disable the logging of warnings based on keys conflicting keys/methods
      #
      # @api semipublic
      # @return [void]
      # @example Disable warnings for selected methods
      #   klass = Class.new(Hashie::Mash)
      #   klass.disable_warnings(:size, :keys)
      #   klass.disabled_warnings # => [:size, :keys]
      def disable_warnings(*method_keys)
        raise CannotDisableMashWarnings if self == Hashie::Mash

        if method_keys.any?
          disabled_warnings.concat(method_keys).tap(&:flatten!).uniq!
        else
          disabled_warnings.clear
        end

        @disable_warnings = true
      end

      # Checks whether this class disables warnings for conflicting keys/methods
      #
      # @api semipublic
      # @return [Boolean]
      # @example Disable all warnings when no methods are specified
      #   klass = Class.new(Hashie::Mash)
      #   klass.disable_warnings
      #   klass.disable_warnings?(:size) # => true
      def disable_warnings?(method_key = nil)
        return disabled_warnings.include?(method_key) if disabled_warnings.any? && method_key

        @disable_warnings ||= false
      end

      # Returns an array of methods that this class disables warnings for.
      #
      # @api semipublic
      # @return [Array<Symbol>]
      # @example Inspect selected warning exclusions
      #   klass = Class.new(Hashie::Mash)
      #   klass.disable_warnings(:size)
      #   klass.disabled_warnings # => [:size]
      def disabled_warnings
        @disabled_warnings ||= []
      end

      # Inheritance hook that sets class configuration when inherited.
      #
      # @api semipublic
      # @return [void]
      # @example Inherit selected warning settings
      #   parent = Class.new(Hashie::Mash)
      #   parent.disable_warnings(:size)
      #   child = Class.new(parent)
      #   child.disabled_warnings # => [:size]
      #   child.disable_warnings?(:keys) # => false
      def inherited(subclass)
        super
        subclass.disable_warnings(disabled_warnings) if disable_warnings?
      end
    end
  end
end
