# frozen_string_literal: true

module Hashie
  module Extensions
    module Dash
      # Extends a Dash with the ability to remap keys from a source hash.
      #
      # Property translation is useful when you need to read data from another
      # application -- such as a Java API -- where the keys are named
      # differently from Ruby conventions.
      #
      # @example Translate inconsistent API keys
      #
      #   class PersonHash < Hashie::Dash
      #     include Hashie::Extensions::Dash::PropertyTranslation
      #
      #     property :first_name, from: :firstName
      #     property :last_name, from: :lastName
      #     property :first_name, from: :f_name
      #     property :last_name, from: :l_name
      #   end
      #
      #   person = PersonHash.new(firstName: 'Michael', l_name: 'Bleigh')
      #   person[:first_name]  #=> 'Michael'
      #   person[:last_name]   #=> 'Bleigh'
      #
      # You can also use a lambda to translate the value. This is particularly
      # useful when you want to ensure the type of data you're wrapping.
      #
      # @example Transform input values
      #   require 'time'
      #
      #   class DataModelHash < Hashie::Dash
      #     include Hashie::Extensions::Dash::PropertyTranslation
      #
      #     property :id, transform_with: ->(value) { value.to_i }
      #     property :created_at, from: :created, with: ->(value) { Time.parse(value) }
      #   end
      #
      #   model = DataModelHash.new(id: '123', created: '2014-04-25 22:35:28')
      #   model.id.class          #=> Integer
      #   model.created_at.class  #=> Time
      module PropertyTranslation
        # @example Install translation declarations on a Dash
        #   klass = Class.new(Hashie::Dash) do
        #     include Hashie::Extensions::Dash::PropertyTranslation
        #     property :name, from: :fullName
        #   end
        #   klass.new(fullName: 'Ada').name # => 'Ada'
        def self.included(base)
          base.instance_variable_set(:@transforms, {})
          base.instance_variable_set(:@translations_hash, ::Hash.new { |hash, key| hash[key] = {} })
          base.extend(ClassMethods)
          base.send(:include, InstanceMethods)
          base.extend Hashie::Extensions::DeepMerge
        end

        # Defines input translations and value transformations.
        #
        # @example
        #   klass = Class.new(Hashie::Dash) do
        #     include Hashie::Extensions::Dash::PropertyTranslation
        #     property :name, from: :fullName
        #   end
        #   klass.translations # => {fullName: :name}
        module ClassMethods
          # @example Inspect value transformers
          #   klass = Class.new(Hashie::Dash) do
          #     include Hashie::Extensions::Dash::PropertyTranslation
          #     property :age, transform_with: ->(value) { value.to_i }
          #   end
          #   klass.transforms[:age].call('37') # => 37
          #   klass.translations_hash # => {}
          attr_reader :transforms, :translations_hash

          # Ensures that any inheriting classes maintain their translations.
          #
          # * `:default` - The class inheriting the translations.
          #
          # @example Copy translation settings to subclasses
          #   parent = Class.new(Hashie::Dash) do
          #     include Hashie::Extensions::Dash::PropertyTranslation
          #     property :name, from: :fullName
          #   end
          #   child = Class.new(parent) { property :age, from: :years }
          #   child.new(fullName: 'Ada', years: 37).age # => 37
          #   parent.translations # => {fullName: :name}
          def inherited(klass)
            super
            klass.instance_variable_set(:@transforms, transforms.dup)
            klass.instance_variable_set(:@translations_hash, _deep_dup(translations_hash))
          end

          # @example List translated input keys alongside untranslated properties
          #   klass = Class.new(Hashie::Dash) do
          #     include Hashie::Extensions::Dash::PropertyTranslation
          #     property :name, from: :fullName
          #     property :age
          #   end
          #   klass.permitted_input_keys # => [:fullName, :age]
          def permitted_input_keys
            @permitted_input_keys ||=
              properties
              .map { |property| inverse_translations.fetch property, property }
          end

          # Defines a property on the Trash. Options are as follows:
          #
          # * `:default` - Specify a default value for this property, to be
          # returned before a value is set on the property in a new Dash.
          # * `:from` - Specify the original key name that will be write only.
          # * `:with` - Specify a lambda to be used to convert value.
          # * `:transform_with` - Specify a lambda to be used to convert value
          # without using the :from option. It transform the property itself.
          #
          # @example Declare a translated and converted property
          #   klass = Class.new(Hashie::Dash) do
          #     include Hashie::Extensions::Dash::PropertyTranslation
          #     property :age, from: :years, with: ->(value) { value.to_i }
          #   end
          #   klass.new(years: '37').age # => 37
          def property(property_name, options = {})
            super

            from = options[:from]
            converter = options[:with]
            transformer = options[:transform_with]

            if from
              fail_self_transformation_error!(property_name) if property_name.to_s == from.to_s
              define_translation(from, property_name, converter || transformer)
              define_writer_for_source_property(from)
            elsif valid_transformer?(transformer)
              transforms[property_name] = transformer
            end
          end

          # @example Apply a declared transformer directly
          #   klass = Class.new(Hashie::Dash) do
          #     include Hashie::Extensions::Dash::PropertyTranslation
          #     property :age, transform_with: ->(value) { value.to_i }
          #   end
          #   klass.transformed_property(:age, '37') # => 37
          def transformed_property(property_name, value)
            transforms[property_name].call(value)
          end

          # @example Check for a property transformer
          #   klass = Class.new(Hashie::Dash) do
          #     include Hashie::Extensions::Dash::PropertyTranslation
          #     property :age, transform_with: ->(value) { value.to_i }
          #   end
          #   klass.transformation_exists?(:age) # => true
          #   klass.transformation_exists?(:name) # => false
          def transformation_exists?(name)
            transforms.key? name
          end

          # @example Check for a translated source key
          #   klass = Class.new(Hashie::Dash) do
          #     include Hashie::Extensions::Dash::PropertyTranslation
          #     property :name, from: :fullName
          #   end
          #   klass.translation_exists?(:fullName) # => true
          #   klass.translation_exists?(:name) # => false
          def translation_exists?(name)
            translations_hash.key? name
          end

          # @example Map source keys to destination properties
          #   klass = Class.new(Hashie::Dash) do
          #     include Hashie::Extensions::Dash::PropertyTranslation
          #     property :name, from: :fullName
          #   end
          #   klass.translations # => {fullName: :name}
          def translations
            @translations ||= {}.tap do |translations|
              translations_hash.each do |(property_name, property_translations)|
                translations[property_name] =
                  if property_translations.size > 1
                    property_translations.keys
                  else
                    property_translations.keys.first
                  end
              end
            end
          end

          # @example Map destination properties back to source keys
          #   klass = Class.new(Hashie::Dash) do
          #     include Hashie::Extensions::Dash::PropertyTranslation
          #     property :name, from: :fullName
          #   end
          #   klass.inverse_translations # => {name: :fullName}
          def inverse_translations
            @inverse_translations ||= {}.tap do |translations|
              translations_hash.each do |(property_name, property_translations)|
                property_translations.each_key do |key|
                  translations[key] = property_name
                end
              end
            end
          end

          private

          def define_translation(from, property_name, translator)
            translations_hash[from][property_name] = translator
          end

          def define_writer_for_source_property(property)
            define_method "#{property}=" do |val|
              __translations[property].each do |name, with|
                self[name] = with.respond_to?(:call) ? with.call(val) : val
              end
            end
          end

          def fail_self_transformation_error!(property_name)
            raise ArgumentError,
                  "property name `#{property_name}` and :from option must not be the same"
          end

          def valid_transformer?(transformer)
            transformer.respond_to? :call
          end
        end

        # Applies translations and transformations during assignment.
        #
        # @example
        #   klass = Class.new(Hashie::Dash) do
        #     include Hashie::Extensions::Dash::PropertyTranslation
        #     property :name, from: :fullName
        #   end
        #   klass.new(fullName: 'Ada').name # => 'Ada'
        module InstanceMethods
          # Sets a value on the Dash in a Hash-like way.
          #
          # Note: Only works on pre-existing properties.
          #
          # @example Assign through a translated source key
          #   klass = Class.new(Hashie::Dash) do
          #     include Hashie::Extensions::Dash::PropertyTranslation
          #     property :name, from: :fullName
          #   end
          #   dash = klass.new
          #   dash[:fullName] = 'Ada'
          #   dash.name # => 'Ada'
          def []=(property, value)
            if self.class.translation_exists? property
              send("#{property}=", value)

              if self.class.transformation_exists? property
                super(property, self.class.transformed_property(property, value))
              elsif self.class.properties.include?(property)
                super
              end
            elsif self.class.transformation_exists? property
              super(property, self.class.transformed_property(property, value))
            elsif property_exists? property
              super
            end
          end

          # Deletes any keys that have a translation
          #
          # @example Initialize translated input without modifying the source
          #   klass = Class.new(Hashie::Dash) do
          #     include Hashie::Extensions::Dash::PropertyTranslation
          #     property :name, from: :fullName
          #   end
          #   attributes = {fullName: 'Ada'}
          #   dash = klass.new
          #   dash.initialize_attributes(attributes)
          #   dash.name # => 'Ada'
          #   attributes # => {fullName: 'Ada'}
          def initialize_attributes(attributes)
            return unless attributes

            attributes_copy = attributes.dup.delete_if do |k, v|
              if self.class.translations_hash.include?(k)
                self[k] = v
                true
              end
            end
            super(attributes_copy)
          end

          # Raises an NoMethodError if the property doesn't exist
          #
          # @example Check for an existing property
          #   klass = Class.new(Hashie::Dash) do
          #     include Hashie::Extensions::Dash::PropertyTranslation
          #     property :name
          #   end
          #   dash = klass.new
          #   dash.property_exists?(:name) # => true
          #   expect { dash.property_exists?(:missing) }.to raise_error(NoMethodError)
          def property_exists?(property)
            fail_no_property_error!(property) unless self.class.property?(property)
            true
          end

          private

          def __translations
            self.class.translations_hash
          end
        end
      end
    end
  end
end
