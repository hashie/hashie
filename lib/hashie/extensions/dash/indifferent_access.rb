# frozen_string_literal: true

module Hashie
  module Extensions
    module Dash
      # Allows string and symbol access to declared Dash properties.
      #
      # @example
      #   klass = Class.new(Hashie::Dash) do
      #     include Hashie::Extensions::Dash::IndifferentAccess
      #     property :name
      #   end
      #   klass.new(name: 'Ada')['name'] # => 'Ada'
      module IndifferentAccess
        # @example Include indifferent access in a Dash subclass
        #   klass = Class.new(Hashie::Dash) do
        #     include Hashie::Extensions::Dash::IndifferentAccess
        #     property :name
        #   end
        #   klass.property?('name') # => true
        def self.included(base)
          base.extend ClassMethods
          base.send :include, Hashie::Extensions::IndifferentAccess
        end

        # @example Add Dash-specific class methods when needed
        #   klass = Class.new(Hashie::Dash) { property :name }
        #   Hashie::Extensions::Dash::IndifferentAccess.maybe_extend(klass)
        #   klass.property?('name') # => true
        #   klass.singleton_class.included_modules.include?(Hashie::Extensions::Dash::IndifferentAccess::ClassMethods) # => true
        def self.maybe_extend(base)
          return unless _requires_class_methods?(base)

          base.extend(ClassMethods)
        end

        def self._requires_class_methods?(klass)
          klass <= Hashie::Dash &&
            !klass.singleton_class.included_modules.include?(ClassMethods)
        end
        private_class_method :_requires_class_methods?

        # @example Include defaults under string keys in the returned hash
        #   klass = Class.new(Hashie::Dash) do
        #     include Hashie::Extensions::Dash::IndifferentAccess
        #     property :name, default: 'Ada'
        #     property :age
        #   end
        #   klass.new(age: 37).to_h # => {'name' => 'Ada', 'age' => 37}
        def to_h
          defaults = self.class.properties.to_h do |prop|
            [Hashie::Extensions::IndifferentAccess.convert_key(prop), self.class.defaults[prop]]
          end

          defaults.merge(self)
        end
        # @example
        #   klass = Class.new(Hashie::Dash) do
        #     include Hashie::Extensions::Dash::IndifferentAccess
        #     property :name, default: 'Ada'
        #   end
        #   klass.new.to_hash # => {'name' => 'Ada'}
        alias to_hash to_h

        # Class-level property and translation lookup with indifferent keys.
        #
        # @example
        #   klass = Class.new(Hashie::Dash) do
        #     include Hashie::Extensions::Dash::IndifferentAccess
        #     property :name
        #   end
        #   klass.property?('name') # => true
        module ClassMethods
          # Check to see if the specified property has already been
          # defined.
          #
          # @example
          #   klass = Class.new(Hashie::Dash) do
          #     include Hashie::Extensions::Dash::IndifferentAccess
          #     property :name
          #   end
          #   klass.property?('name') # => true
          #   klass.property?(:missing) # => false
          def property?(name)
            targets = if _translation_for?(name)
                        Array(translations.find { |key, _| key.to_s == name.to_s }.last)
                      else
                        [name]
                      end
            targets.all? do |target|
              properties.any? { |property| property.to_s == target.to_s }
            end
          end

          # @example Look up a translation with a string or symbol
          #   klass = Class.new(Hashie::Dash) do
          #     include Hashie::Extensions::Dash::PropertyTranslation
          #     include Hashie::Extensions::Dash::IndifferentAccess
          #     property :name, from: :fullName
          #   end
          #   klass.translation_exists?('fullName') # => true
          #   klass.translation_exists?(:missing) # => false
          def translation_exists?(name)
            name = name.to_s
            !!translations.keys.find { |key| key.to_s == name }
          end

          # @example Apply a transformer declared with a symbol key
          #   klass = Class.new(Hashie::Dash) do
          #     include Hashie::Extensions::Dash::PropertyTranslation
          #     include Hashie::Extensions::Dash::IndifferentAccess
          #     property :age, transform_with: ->(value) { value.to_i }
          #   end
          #   klass.transformed_property('age', '37') # => 37
          def transformed_property(property_name, value)
            transform = transforms[property_name] || transforms[property_name.to_sym]
            transform.call(value)
          end

          # @example Find a transformer regardless of key type
          #   klass = Class.new(Hashie::Dash) do
          #     include Hashie::Extensions::Dash::PropertyTranslation
          #     include Hashie::Extensions::Dash::IndifferentAccess
          #     property :age, transform_with: ->(value) { value.to_i }
          #   end
          #   klass.transformation_exists?('age') # => true
          #   klass.transformation_exists?(:missing) # => false
          def transformation_exists?(name)
            name = name.to_s
            !!transforms.keys.find { |key| key.to_s == name }
          end

          private

          def _translation_for?(name)
            included_modules.include?(Hashie::Extensions::Dash::PropertyTranslation) &&
              translation_exists?(name)
          end
        end
      end
    end
  end
end
