require 'hashie/hash'

module Hashie
  include Hashie::PrettyInspect
  # A Dash is a 'defined' or 'discrete' Hash, that is, a Hash
  # that has a set of defined keys that are accessible (with
  # optional defaults) and only those keys may be set or read.
  #
  # Dashes are useful when you need to create a very simple
  # lightweight data object that needs even fewer options and
  # resources than something like a DataMapper resource.
  #
  # It is preferrable to a Struct because of the in-class
  # API for defining properties as well as per-property defaults.
  class Dash < Hashie::Hash
    include Hashie::PrettyInspect
    alias_method :to_s, :inspect

    # Defines a property on the Dash. Options are
    # as follows:
    #
    # * <tt>:default</tt> - Specify a default value for this property,
    #   to be returned before a value is set on the property in a new
    #   Dash.
    #
    def self.property(property_name, options = {})
      property_name = property_name.to_sym

      (@properties ||= []) << property_name
      (@defaults ||= {})[property_name] = options.delete(:default)

      class_eval <<-RUBY
        def #{property_name}
          self[:#{property_name}]
        end

        def #{property_name}=(val)
          self[:#{property_name}] = val
        end
      RUBY
    end

    # Get a String array of the currently defined
    # properties on this Dash.
    def self.properties
      properties = []
      ancestors.each do |elder|
        if elder.instance_variable_defined?("@properties")
          properties << elder.instance_variable_get("@properties")
        end
      end

      properties.flatten.map{|p| p.to_s}
    end

    # Check to see if the specified property has already been
    # defined.
    def self.property?(prop)
      properties.include?(prop.to_s)
    end

    # The default values that have been set for this Dash
    def self.defaults
      properties = {}
      ancestors.each do |elder|
        if elder.instance_variable_defined?("@defaults")
          properties.merge! elder.instance_variable_get("@defaults")
        end
      end

      properties
    end

    # You may initialize a Dash with an attributes hash
    # just like you would many other kinds of data objects.
    def initialize(attributes = {})
      self.class.properties.each do |prop|
        self.send("#{prop}=", self.class.defaults[prop.to_sym])
      end

      attributes.each_pair do |att, value|
        self.send("#{att}=", value)
      end if attributes
    end

    # Retrieve a value from the Dash (will return the
    # property's default value if it hasn't been set).
    def [](property)
      super(property.to_sym) if property_exists? property
    end

    # Set a value on the Dash in a Hash-like way. Only works
    # on pre-existing properties.
    def []=(property, value)
      super if property_exists? property
    end

    private
      # Raises an NoMethodError if the property doesn't exist
      #
      def property_exists?(property)
        unless self.class.property?(property.to_sym)
          raise NoMethodError, "The property '#{property}' is not defined for this Dash."
        end
        true
      end
  end
end
