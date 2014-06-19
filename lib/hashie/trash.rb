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

      options[:from] = options[:from] if options[:from]

      if options[:from]
        if property_name == options[:from]
          fail ArgumentError, "Property name (#{property_name}) and :from option must not be the same"
        end

        translations[options[:from]] = property_name

        define_method "#{options[:from]}=" do |val|
          with = options[:with] || options[:transform_with]
          self[property_name] = with.respond_to?(:call) ? with.call(val) : val
        end
      else
        if options[:transform_with].respond_to? :call
          transforms[property_name] = options[:transform_with]
        end
      end
    end

    # Set a value on the Dash in a Hash-like way. Only works
    # on pre-existing properties.
    def []=(property, value)
      if self.class.translation_exists? property
        send("#{property}=", value)
      elsif self.class.transformation_exists? property
        super property, self.class.transformed_property(property, value)
      elsif property_exists? property
        super
      end
    end

    def self.transformed_property(property_name, value)
      transforms[property_name].call(value)
    end

    def self.translation_exists?(name)
      translations.key? name
    end

    def self.transformation_exists?(name)
      transforms.key? name
    end

    def self.permitted_input_keys
      @permitted_input_keys ||= properties.map { |property| inverse_translations.fetch property, property }
    end

    private

    def self.properties
      @properties ||= []
    end

    def self.translations
      @translations ||= {}
    end

    def self.inverse_translations
      @inverse_translations ||= Hash[translations.map(&:reverse)]
    end

    def self.transforms
      @transforms ||= {}
    end

    # Raises an NoMethodError if the property doesn't exist
    #
    def property_exists?(property)
      fail_no_property_error!(property) unless self.class.property?(property)
      true
    end

    private

    # Deletes any keys that have a translation
    def initialize_attributes(attributes)
      return unless attributes
      attributes_copy = attributes.dup.delete_if do |k, v|
        if self.class.translations.include?(k)
          self[k] = v
          true
        end
      end
      super attributes_copy
    end
  end
end
