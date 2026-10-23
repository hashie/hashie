# frozen_string_literal: true

module Hashie
  # A collection of helper methods that can be used throughout the gem.
  #
  # @example Duplicate mutable values safely
  #   Hashie::Utils.safe_dup(['Ada']) # => ['Ada']
  module Utils
    # Describes a method by where it was defined.
    #
    # @param bound_method [Method] The method to describe.
    # @return [String]
    #
    # @example Describe a built-in method
    #   Hashie::Utils.method_information('name'.method(:upcase)) # => 'defined in String'
    def self.method_information(bound_method)
      if bound_method.source_location
        "defined at #{bound_method.source_location.join(':')}"
      else
        "defined in #{bound_method.owner}"
      end
    end

    # Duplicates a value or returns the value when it is not duplicable
    #
    # @api public
    #
    # @param value [Object] the value to safely duplicate
    # @return [Object] the duplicated value
    #
    # @example Copy a mutable value without copying immutable symbols
    #   original = ['Ada']
    #   copy = Hashie::Utils.safe_dup(original)
    #   copy << 'Grace'
    #   original # => ['Ada']
    #   copy # => ['Ada', 'Grace']
    #   Hashie::Utils.safe_dup(:name) # => :name
    def self.safe_dup(value)
      case value
      when Complex, FalseClass, NilClass, Rational, Method, Symbol, TrueClass, *_integer_classes
        value
      else
        value.dup
      end
    end

    # Lists the classes Ruby uses for integers
    #
    # @api private
    # @return [Array<Class>]
    def self._integer_classes
      @integer_classes ||= [Integer]
    end
    private_class_method :_integer_classes
  end
end
