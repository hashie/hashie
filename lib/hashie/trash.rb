require 'hashie/dash'

module Hashie
  # A Trash is a 'translated' Dash where the keys can be remapped from a source
  # hash.
  #
  # Trashes are useful when you need to read data from another application,
  # such as a Java api, where the keys are named differently from how we would
  # in Ruby.
  class Trash < Dash

    # Defines a property on the Trash. Options are as follows:
    #
    # * <tt>:default</tt> - Specify a default value for this property, to be
    # returned before a value is set on the property in a new Dash.
    # * <tt>:from</tt> - Specify the original key name that will be write only.
    # * <tt>:with</tt> - Specify a lambda to be used to convert value.
    # * <tt>:transform_with</tt> - Specify a lambda to be used to convert value
    # without using the :from option. It transform the property itself.
    def self.property(property_name, options = {})
      super

      options[:from] = options[:from].to_sym if options[:from]
      property_name = property_name.to_sym

      if options[:from]
        if property_name == options[:from]
          raise ArgumentError, "Property name (#{property_name}) and :from option must not be the same"
        end

        translations[options[:from]] ||= {}
        translations[options[:from]][property_name] = options[:with] || options[:transform_with] # Issue #58

        # NOTE: may overwrite existing method multiple times
        define_method "#{options[:from]}=" do |val|
          self.class.translations[options[:from]].each do |property_name, with|
            self[property_name] = with.respond_to?(:call) ? with.call(val) : val
          end
        end
      else
        if options[:transform_with].respond_to? :call
          transforms[property_name.to_sym] = options[:transform_with]
        end
      end
    end

    # Set a value on the Dash in a Hash-like way. Only works
    # on pre-existing properties.
    def []=(property, value)
      if self.class.translations.key? property.to_sym
        send("#{property}=", value)
      elsif self.class.transforms.key? property.to_sym
        super property, self.class.transforms[property.to_sym].call(value)
      elsif property_exists? property
        super
      end
    end

    private

    def self.properties
      @properties ||= []
    end

    def self.translations
      @translations ||= {} # NOTE: Hash.new { {} } ? to provide lazy value initialization for new keys
    end

    def self.transforms
      @transforms ||= {}
    end

    # Raises an NoMethodError if the property doesn't exist
    #
    def property_exists?(property)
      unless self.class.property?(property.to_sym)
        raise NoMethodError, "The property '#{property}' is not defined for this Trash."
      end
      true
    end

    private

    # Deletes any keys that have a translation
    def initialize_attributes(attributes)
      return unless attributes
      attributes_copy = attributes.dup.delete_if do |k,v|
        if self.class.translations.include?(k.to_sym)
          self[k] = v
          true
        end
      end
      super attributes_copy
    end
  end
end