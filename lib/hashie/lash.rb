require 'hashie/dash'

module Hashie
  # A Lash is just like a Dash, except that a Lash allows
  # that properties can set as required. This means that if
  # an attempt is made to create a Lash with out it, an error
  # will be raised.
  #
  # Dashes are useful when you need to create a very simple
  # lightweight data object that needs even fewer options and
  # resources than something like a DataMapper resource, and
  # certain attributes are required.
  #
  # It is preferrable to a Struct because of the in-class
  # API for defining properties as well as per-property defaults
  # and requirements.
  class Lash < Hashie::Dash

    # Defines a property on the Lash. Options are
    # as follows:
    #
    # * <tt>:default</tt> - Specify a default value for this property,
    #   to be returned before a value is set on the property in a new
    #   Lash.
    #
    # * <tt>:required</tt> - Specify the value as required for this
    #   property, to raise an error if a value is unset in a new or
    #   existing Lash.
    #
    def self.property(property_name, options = {})
      super
      required_properties << property_name if options.delete(:required)
    end

    class << self
      attr_reader :required_properties
    end
    instance_variable_set('@required_properties', Set.new)

    def self.inherited(klass)
      super
      klass.instance_variable_set('@required_properties', self.required_properties.dup)
    end

    # Check to see if the specified property is
    # required.
    def self.required?(name)
      required_properties.include? name.to_sym
    end

    # You may initialize a Lash with an attributes hash
    # just like you would many other kinds of data objects.
    # Remember to pass in the values for the properties
    # you set as required.
    def initialize(attributes = {}, &block)
      super(attributes, &block)
      assert_required_properties_set!
    end

    # Set a value on the Lash in a Hash-like way. Only works
    # on pre-existing properties and errors if you try to
    # set a required value to nil.
    def []=(property, value)
      assert_property_required! property, value
      super(property.to_s, value)
    end


    private

      def assert_required_properties_set!
        self.class.required_properties.each do |required_property|
          assert_property_set!(required_property)
        end
      end

      def assert_property_set!(property)
        if send(property).nil?
          raise ArgumentError, "The property '#{property}' is required for this Lash."
        end
      end

      def assert_property_required!(property, value)
        if self.class.required?(property) && value.nil?
          raise ArgumentError, "The property '#{property}' is required for this Lash."
        end
      end
  end
end
