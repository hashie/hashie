# frozen_string_literal: true

module Hashie
  module Extensions
    module Dash
      # Loads declared properties on demand from an initializer block.
      # Include after other Dash extensions. Hash enumeration only sees loaded
      # entries; to_h loads every declared property.
      #
      # @example Load and memoize a property
      #   klass = Class.new(Hashie::Dash) do
      #     include Hashie::Extensions::Dash::Lazy
      #     property :name
      #   end
      #   calls = []
      #   dash = klass.new { |key| calls << key; 'Ada' }
      #   calls # => []
      #   dash.name # => 'Ada'
      #   dash.name # => 'Ada'
      #   calls # => [:name]
      module Lazy
        # @example Hash initialization without a loader retains normal behavior
        #   klass = Class.new(Hashie::Dash) do
        #     include Hashie::Extensions::Dash::Lazy
        #     property :name, required: true
        #   end
        #   klass.new(name: 'Ada').name # => 'Ada'
        def initialize(attributes = {}, &loader)
          @lazy_loader = loader
          @lazy_loading = []
          super(attributes, &nil)
        end

        # @example Read a property without loading its neighbors
        #   klass = Class.new(Hashie::Dash) do
        #     include Hashie::Extensions::Dash::Lazy
        #     property :name
        #     property :age
        #   end
        #   dash = klass.new { |key| { name: 'Ada', age: 37 }[key] }
        #   dash[:name] # => 'Ada'
        #   dash.keys # => [:name]
        def [](property, &block)
          return super unless @lazy_loader

          _assert_property_exists!(property)
          canonical_property = _lazy_property(property)
          _load_property(canonical_property) unless key?(property)
          value = super
          _assert_property_required!(canonical_property, value)
          value
        end

        # @example Fetch a declared value through its loader
        #   klass = Class.new(Hashie::Dash) do
        #     include Hashie::Extensions::Dash::Lazy
        #     property :name
        #   end
        #   klass.new { |_key| 'Ada' }.fetch(:name) # => 'Ada'
        def fetch(property, *args, &block)
          self[property] if @lazy_loader && self.class.property?(property)
          super
        end

        # @example Load the first property before digging into its value
        #   klass = Class.new(Hashie::Dash) do
        #     include Hashie::Extensions::Dash::Lazy
        #     property :user
        #   end
        #   klass.new { |_key| { name: 'Ada' } }.dig(:user, :name) # => 'Ada'
        def dig(property, *path)
          self[property] if @lazy_loader && self.class.property?(property)
          super
        end

        # @example Convert all declared properties to a plain hash
        #   klass = Class.new(Hashie::Dash) do
        #     include Hashie::Extensions::Dash::Lazy
        #     property :name
        #   end
        #   klass.new { |_key| 'Ada' }.to_h # => { name: 'Ada' }
        def to_h
          self.class.properties.each { |property| self[property] } if @lazy_loader
          super
        end

        # @example Convert all declared properties for hash coercion
        #   klass = Class.new(Hashie::Dash) do
        #     include Hashie::Extensions::Dash::Lazy
        #     property :name
        #   end
        #   klass.new { |_key| 'Ada' }.to_hash # => { name: 'Ada' }
        alias to_hash to_h

        # @example Freezing resolves pending values before preventing mutation
        #   klass = Class.new(Hashie::Dash) do
        #     include Hashie::Extensions::Dash::Lazy
        #     property :name
        #   end
        #   klass.new { |_key| 'Ada' }.freeze.name # => 'Ada'
        def freeze
          to_h if @lazy_loader && !frozen?
          super
        end

        private

        def initialize_attributes(attributes)
          return super unless @lazy_loader

          @lazy_attributes = attributes || {}
        end

        def _assert_required_attributes_set!
          super unless @lazy_loader
        end

        def initialize_copy(other)
          super
          @lazy_loading = []
        end

        def _lazy_property(property)
          return property if self.class.properties.include?(property)

          self.class.properties.find { |key| key.to_s == property.to_s } || property
        end

        def _lazy_attribute_key(property)
          return property if @lazy_attributes.key?(property)
          return unless respond_to?(:convert_key)

          converted = convert_key(property)
          converted if @lazy_attributes.key?(converted)
        end

        def _load_property(property)
          raise ArgumentError, "circular lazy loading for property `#{property}`" if @lazy_loading.include?(property)

          @lazy_loading << property
          begin
            source = if self.class.respond_to?(:inverse_translations)
                       self.class.inverse_translations.fetch(property, property)
                     else
                       property
                     end
            attribute = _lazy_attribute_key(property)
            if attribute
              source = property
              value = @lazy_attributes[attribute]
            else
              attribute = _lazy_attribute_key(source)
              value = attribute ? @lazy_attributes[attribute] : @lazy_loader.call(source)
            end
            if value.nil?
              value = self.class.defaults[property].dup
              value = value.arity == 1 ? value.call(self) : value.call if value.is_a?(Proc)
            elsif source != property
              translator = self.class.translations_hash[source][property]
              value = translator.call(value) if translator.respond_to?(:call)
            end
            self[property] = value
          ensure
            @lazy_loading.pop
          end
        end
      end
    end
  end
end
