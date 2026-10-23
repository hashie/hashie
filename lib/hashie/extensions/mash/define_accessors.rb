# frozen_string_literal: true

module Hashie
  module Extensions
    module Mash
      # Generates reusable methods as Mash properties are accessed.
      #
      # @example
      #   klass = Class.new(Hashie::Mash) do
      #     include Hashie::Extensions::Mash::DefineAccessors
      #   end
      #   klass.new(name: 'Ada').name # => 'Ada'
      module DefineAccessors
        # @example Install generated accessors on a subclass
        #   klass = Class.new(Hashie::Mash)
        #   klass.include(Hashie::Extensions::Mash::DefineAccessors)
        #   klass.new(quantity: 2).quantity # => 2
        def self.included(klass)
          klass.class_eval do
            mod = Ext.new
            include mod
          end
        end

        # @example Install generated accessors on one Mash
        #   mash = Hashie::Mash.new(quantity: 2)
        #   mash.extend(Hashie::Extensions::Mash::DefineAccessors)
        #   mash.quantity # => 2
        def self.extended(obj)
          included(obj.singleton_class)
        end

        # A module of lazily generated accessors for a Mash class.
        #
        # @example
        #   accessors = Hashie::Extensions::Mash::DefineAccessors::Ext.new
        #   klass = Class.new(Hashie::Mash) { include accessors }
        #   mash = klass.new(name: 'Ada')
        #   accessors.define_reader('name', :name)
        #   mash.name # => 'Ada'
        class Ext < Module
          # @example Generate a method on first access
          #   accessors = Hashie::Extensions::Mash::DefineAccessors::Ext.new
          #   klass = Class.new(Hashie::Mash) { include accessors }
          #   klass.new(name: 'Ada').name # => 'Ada'
          #   accessors.instance_methods(false).include?(:name) # => true
          def initialize
            mod = self
            define_method(:method_missing) do |method_name, *args, &block|
              key, suffix = method_name_and_suffix(method_name)
              case suffix
              when '='
                mod.define_writer(key, method_name)
              when '?'
                mod.define_predicate(key, method_name)
              when '!'
                mod.define_initializing_reader(key, method_name)
              when '_'
                mod.define_underbang_reader(key, method_name)
              else
                mod.define_reader(key, method_name)
              end
              send(method_name, *args, &block)
            end
          end

          # @example
          #   accessors = Hashie::Extensions::Mash::DefineAccessors::Ext.new
          #   klass = Class.new(Hashie::Mash) { include accessors }
          #   mash = klass.new(name: 'Ada')
          #   accessors.define_reader('name', :name)
          #   mash.name # => 'Ada'
          def define_reader(key, method_name)
            define_method(method_name) do |&block|
              if key? method_name
                self.[](method_name, &block)
              else
                self.[](key, &block)
              end
            end
          end

          # @example
          #   accessors = Hashie::Extensions::Mash::DefineAccessors::Ext.new
          #   accessors.define_writer('name', :name=)
          #   klass = Class.new(Hashie::Mash) { include accessors }
          #   mash = klass.new
          #   mash.name = 'Ada'
          #   mash['name'] # => 'Ada'
          def define_writer(key, method_name)
            define_method(method_name) do |value = nil|
              if key? method_name
                self.[](method_name)
              else
                assign_property(key, value)
              end
            end
          end

          # @example
          #   accessors = Hashie::Extensions::Mash::DefineAccessors::Ext.new
          #   accessors.define_predicate('name', :name?)
          #   klass = Class.new(Hashie::Mash) { include accessors }
          #   klass.new(name: 'Ada').name? # => true
          #   klass.new.name? # => false
          def define_predicate(key, method_name)
            define_method(method_name) do
              if key? method_name
                self.[](method_name)
              else
                !!self[key]
              end
            end
          end

          # @example
          #   accessors = Hashie::Extensions::Mash::DefineAccessors::Ext.new
          #   accessors.define_initializing_reader('address', :address!)
          #   klass = Class.new(Hashie::Mash) { include accessors }
          #   mash = klass.new
          #   mash.address!.city = 'London'
          #   mash.address.city # => 'London'
          def define_initializing_reader(key, method_name)
            define_method(method_name) do
              if key? method_name
                self.[](method_name)
              else
                initializing_reader(key)
              end
            end
          end

          # @example
          #   accessors = Hashie::Extensions::Mash::DefineAccessors::Ext.new
          #   accessors.define_underbang_reader('address', :address_)
          #   klass = Class.new(Hashie::Mash) { include accessors }
          #   mash = klass.new
          #   mash.address_.city = 'London'
          #   mash.key?('address') # => false
          def define_underbang_reader(key, method_name)
            define_method(method_name) do
              if key? method_name
                self.[](key)
              else
                underbang_reader(key)
              end
            end
          end
        end
      end
    end
  end
end
