require 'hashie/hash'

module Hashie
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
          self['#{property_name}']
        end
        
        def #{property_name}=(val)
          self['#{property_name}'] = val
        end
      RUBY
    end
    
    # Get a String array of the currently defined
    # properties on this Dash.
    def self.properties
      @properties.collect{|p| p.to_s}
    end
    
    # Check to see if the specified property has already been
    # defined.
    def self.property?(prop)
      properties.include?(prop.to_s)
    end
    
    # The default values that have been set for this Dash
    def self.defaults
      @defaults
    end
    
    # Retrieve a value from the Dash (will return the
    # property's default value if it hasn't been set).
    def [](property_name)
      super || self.class.defaults[property_name.to_sym]
    end
    
    # Set a value on the Dash in a Hash-like way. Only works
    # on pre-existing properties.
    def []=(property, value)
      if self.class.property?(property)
        super
      else
        raise NoMethodError, 'You may only set pre-defined properties.'
      end
    end
  end
end