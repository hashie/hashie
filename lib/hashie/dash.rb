# frozen_string_literal: true

require 'hashie/hash'
require 'set'

module Hashie
  # A Dash is a 'defined' or 'discrete' Hash, that is, a Hash
  # that has a set of defined keys that are accessible (with
  # optional defaults) and only those keys may be set or read.
  #
  # Dashes are useful when you need to create a very simple
  # lightweight data object that needs even fewer options and
  # resources than something like a DataMapper resource.
  #
  # It is preferable to a Struct because of the in-class
  # API for defining properties as well as per-property defaults.
  #
  # @example Define a lightweight data object
  #   klass = Class.new(Hashie::Dash) { property :name, default: 'Ada' }
  #   klass.new.name # => 'Ada'
  class Dash < Hash
    include Hashie::Extensions::PrettyInspect

    # @example Inspect declared properties
    #   klass = Class.new(Hashie::Dash) { property :name }
    #   klass.new(name: 'Ada').to_s.include?('name="Ada"') # => true
    alias to_s inspect

    # Defines a property on the Dash. Options are
    # as follows:
    #
    # * <tt>:default</tt> - Specify a default value for this property,
    #   to be returned before a value is set on the property in a new
    #   Dash.
    #
    # * <tt>:required</tt> - Specify the value as required for this
    #   property, to raise an error if a value is unset in a new or
    #   existing Dash. If a Proc is provided, it will be run in the
    #   context of the Dash instance. If a Symbol is provided, the
    #   property it represents must not be nil. The property is only
    #   required if the value is truthy.
    #
    # * <tt>:message</tt> - Specify custom error message for required property
    #
    # @example Declare a required property and a default
    #   klass = Class.new(Hashie::Dash) do
    #     property :name, required: true
    #     property :active, default: true
    #   end
    #   klass.new(name: 'Ada').to_h # => { name: 'Ada', active: true }
    def self.property(property_name, options = {})
      properties << property_name

      if options.key?(:default)
        defaults[property_name] = options[:default]
      elsif defaults.key?(property_name)
        defaults.delete property_name
      end

      define_getter_for(property_name)
      define_setter_for(property_name)

      @subclasses.each { |klass| klass.property(property_name, options) } if defined? @subclasses

      condition = options.delete(:required)
      if condition
        message = options.delete(:message) || "is required for `#{name}`"
        required_properties[property_name] = { condition: condition, message: message }
      elsif options.key?(:message)
        raise ArgumentError, 'the :message option should be used with :required option'
      end
    end

    class << self
      # @example List the declared properties
      #   klass = Class.new(Hashie::Dash) { property :name }
      #   klass.properties.to_a # => [:name]
      attr_reader :properties

      # @example Read declared default values
      #   klass = Class.new(Hashie::Dash) { property :active, default: true }
      #   klass.defaults # => { active: true }
      attr_reader :defaults

      # @example List generated getter names
      #   klass = Class.new(Hashie::Dash) { property :name }
      #   klass.getters.to_a # => [:name]
      attr_reader :getters

      # @example Inspect the requirement configured for a property
      #   klass = Class.new(Hashie::Dash) { property :name, required: true, message: 'must be supplied' }
      #   klass.required_properties # => { name: { condition: true, message: 'must be supplied' } }
      attr_reader :required_properties
    end
    instance_variable_set('@properties', Set.new)
    instance_variable_set('@getters', Set.new)
    instance_variable_set('@defaults', {})
    instance_variable_set('@required_properties', {})

    # @example Subclasses inherit independent property definitions
    #   parent = Class.new(Hashie::Dash) { property :name, default: 'Ada' }
    #   child = Class.new(parent) { property :active, default: true }
    #   child.new.to_h # => { name: 'Ada', active: true }
    #   parent.properties.to_a # => [:name]
    def self.inherited(klass)
      super
      (@subclasses ||= Set.new) << klass
      klass.instance_variable_set('@properties', properties.dup)
      klass.instance_variable_set('@getters', getters.dup)
      klass.instance_variable_set('@defaults', defaults.dup)
      klass.instance_variable_set('@required_properties', required_properties.dup)
    end

    # Check to see if the specified property has already been
    # defined.
    #
    # @example Check declared and undeclared properties
    #   klass = Class.new(Hashie::Dash) { property :name }
    #   klass.property?(:name) # => true
    #   klass.property?(:missing) # => false
    def self.property?(name)
      properties.include? name
    end

    # Check to see if the specified property is
    # required.
    #
    # @example Identify a required declaration
    #   klass = Class.new(Hashie::Dash) { property :name, required: true }
    #   klass.required?(:name) # => true
    #   klass.required?(:missing) # => false
    def self.required?(name)
      required_properties.key? name
    end

    private_class_method def self.define_getter_for(property_name)
      return if getters.include?(property_name)

      define_method(property_name) { |&block| self.[](property_name, &block) }
      getters << property_name
    end

    private_class_method def self.define_setter_for(property_name)
      setter = :"#{property_name}="
      return if method_defined?(setter)

      define_method(setter) { |value| self.[]=(property_name, value) }
    end

    # You may initialize a Dash with an attributes hash
    # just like you would many other kinds of data objects.
    #
    # @example Initialize declared attributes and defaults
    #   klass = Class.new(Hashie::Dash) do
    #     property :name
    #     property :active, default: true
    #   end
    #   klass.new(name: 'Ada').to_h # => { name: 'Ada', active: true }
    def initialize(attributes = {}, &block)
      super(&block)

      initialize_attributes(attributes)
      assert_required_attributes_set!
    end

    alias _regular_reader []
    alias _regular_writer []=
    private :_regular_reader, :_regular_writer

    # Retrieve a value from the Dash (will return the
    # property's default value if it hasn't been set).
    #
    # @example Read a declared value by key
    #   klass = Class.new(Hashie::Dash) { property :name, default: 'Ada' }
    #   klass.new[:name] # => 'Ada'
    def [](property)
      assert_property_exists! property
      value = super
      # If the value is a lambda, proc, or whatever answers to call, eval the thing!
      if value.is_a? Proc
        self[property] = value.call # Set the result of the call as a value
      else
        yield value if block_given?
        value
      end
    end

    # Set a value on the Dash in a Hash-like way. Only works
    # on pre-existing properties.
    #
    # @example Assign a declared property
    #   klass = Class.new(Hashie::Dash) { property :name }
    #   dash = klass.new
    #   dash[:name] = 'Ada'
    #   dash.name # => 'Ada'
    def []=(property, value)
      assert_property_required! property, value
      assert_property_exists! property
      super
    end

    # @example Merge into a copy with conflict resolution
    #   klass = Class.new(Hashie::Dash) { property :count }
    #   dash = klass.new(count: 2)
    #   dash.merge(count: 3) { |_key, old, new| old + new }.to_h # => { count: 5 }
    #   dash.count # => 2
    def merge(other_hash)
      new_dash = dup
      other_hash.each do |k, v|
        new_dash[k] = block_given? ? yield(k, self[k], v) : v
      end
      new_dash
    end

    # @example Merge declared values in place
    #   klass = Class.new(Hashie::Dash) { property :name }
    #   dash = klass.new(name: 'Ada')
    #   dash.merge!(name: 'Grace')
    #   dash.name # => 'Grace'
    def merge!(other_hash)
      other_hash.each do |k, v|
        self[k] = block_given? ? yield(k, self[k], v) : v
      end
      self
    end

    # @example Restore defaults for omitted attributes
    #   klass = Class.new(Hashie::Dash) do
    #     property :name
    #     property :active, default: true
    #   end
    #   dash = klass.new(name: 'Ada', active: false)
    #   dash.replace(name: 'Grace').to_h # => { name: 'Grace', active: true }
    def replace(other_hash)
      other_hash = self.class.defaults.merge(other_hash)
      (keys - other_hash.keys).each { |key| delete(key) }
      other_hash.each { |key, value| self[key] = value }
      self
    end

    # @example Include declared but unset properties in a plain hash
    #   klass = Class.new(Hashie::Dash) { property :name }
    #   klass.new.to_h # => { name: nil }
    #   klass.new.to_h.class # => Hash
    def to_h
      defaults = self.class.properties.to_h { |prop| [prop, self.class.defaults[prop]] }

      defaults.merge(self)
    end
    # @example Convert a Dash to a plain hash
    #   klass = Class.new(Hashie::Dash) { property :name }
    #   klass.new(name: 'Ada').to_hash # => { name: 'Ada' }
    alias to_hash to_h

    # ActiveSupport's Hash#deep_transform_keys builds up its result via
    # `self.class.new`, expecting to be able to start from an empty hash
    # and fill in keys one at a time. Since Dash enforces required
    # properties at initialization and restricts which keys may be set,
    # this breaks for Dash (and Trash) - see
    # https://github.com/hashie/hashie/issues/559. Deep transforming a
    # Dash's keys no longer produces a valid Dash anyway (the resulting
    # keys may not correspond to any defined property), so fall back to
    # operating on a plain Hash instead.
    #
    # @example Transform nested keys without Dash's property restrictions
    #   klass = Class.new(Hashie::Dash) { property :user }
    #   dash = klass.new(user: { name: 'Ada' })
    #   dash.deep_transform_keys(&:to_s) # => { 'user' => { 'name' => 'Ada' } }
    def deep_transform_keys(&block)
      _deep_transform_keys_in_object(to_h, &block)
    end

    # @example Update attributes and reapply defaults for nil values
    #   klass = Class.new(Hashie::Dash) { property :name, default: 'Ada' }
    #   dash = klass.new(name: 'Grace')
    #   dash.update_attributes!(name: nil)
    #   dash.name # => 'Ada'
    def update_attributes!(attributes)
      update_attributes(attributes)

      self.class.defaults.each_pair do |prop, value|
        next unless fetch(prop, nil).nil?

        self[prop] = begin
          val = value.dup
          if val.is_a?(Proc)
            val.arity == 1 ? val.call(self) : val.call
          else
            val
          end
        rescue TypeError
          value
        end
      end

      assert_required_attributes_set!
    end

    private

    def initialize_attributes(attributes)
      return unless attributes

      cleaned_attributes = attributes.compact
      update_attributes!(cleaned_attributes)
    end

    def update_attributes(attributes)
      return unless attributes

      attributes.each_pair do |att, value|
        self[att] = value
      end
    end

    def assert_property_exists!(property)
      fail_no_property_error!(property) unless self.class.property?(property)
    end

    def assert_required_attributes_set!
      self.class.required_properties.each_key do |required_property|
        assert_property_set!(required_property)
      end
    end

    def assert_property_set!(property)
      fail_property_required_error!(property) if send(property).nil? && _required?(property)
    end

    def assert_property_required!(property, value)
      fail_property_required_error!(property) if value.nil? && _required?(property)
    end

    def fail_property_required_error!(property)
      message = self.class.required_properties[property][:message]
      raise ArgumentError,
            "the property `#{property}` " + message
    end

    def fail_no_property_error!(property)
      raise NoMethodError,
            "the property `#{property}` is not defined for `#{self.class.name || 'anonymous class'}`"
    end

    def _required?(property)
      return false unless self.class.required?(property)

      condition = self.class.required_properties[property][:condition]
      case condition
      when Proc   then !!instance_exec(&condition)
      when Symbol then !!send(condition)
      else             !!condition
      end
    end

    def _deep_transform_keys_in_object(object, &block)
      case object
      when ::Hash
        object.each_with_object({}) do |(key, value), result|
          result[yield(key)] = _deep_transform_keys_in_object(value, &block)
        end
      when Array
        object.map { |e| _deep_transform_keys_in_object(e, &block) }
      else
        object
      end
    end
  end
end
