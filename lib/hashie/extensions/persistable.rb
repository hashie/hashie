# frozen_string_literal: true

require 'psych'
require 'tempfile'

module Hashie
  module Extensions
    # Opt-in YAML file persistence for classes initialized from a hash.
    #
    # @example Save and reload a hash subclass
    #   class Settings < Hash
    #     include Hashie::Extensions::MergeInitializer
    #     include Hashie::Extensions::Persistable
    #   end
    #   file = Tempfile.new(['hashie-example', '.yaml'], Dir.pwd)
    #   begin
    #     settings = Settings.new('theme' => 'dark')
    #     settings.save(file.path)
    #     Settings.load(file.path)['theme'] # => 'dark'
    #   ensure
    #     file.close!
    #   end
    module Persistable
      def self.included(base)
        base.extend ClassMethods
      end

      # @example Add a YAML loader by including Persistable
      #   class Settings < Hash
      #     include Hashie::Extensions::MergeInitializer
      #     include Hashie::Extensions::Persistable
      #   end
      #   file = Tempfile.new(['hashie-example', '.yaml'], Dir.pwd)
      #   begin
      #     file.write("---\ntheme: dark\n")
      #     file.flush
      #     Settings.load(file.path) # => { 'theme' => 'dark' }
      #   ensure
      #     file.close!
      #   end
      module ClassMethods
        # @example Load safe YAML data and remember its path
        #   class Settings < Hash
        #     include Hashie::Extensions::MergeInitializer
        #     include Hashie::Extensions::Persistable
        #   end
        #   file = Tempfile.new(['hashie-example', '.yaml'], Dir.pwd)
        #   begin
        #     file.write("---\ntheme: dark\n")
        #     file.flush
        #     settings = Settings.load(file.path)
        #     settings['theme'] # => 'dark'
        #     settings.persistable_path # => File.expand_path(file.path)
        #   ensure
        #     file.close!
        #   end
        def load(path)
          path = File.expand_path(File.path(path))
          data = Psych.safe_load(File.read(path), permitted_classes: [Symbol], aliases: false)
          raise TypeError, 'persisted YAML must contain a hash' unless data.is_a?(::Hash)

          new(data).tap { |object| object.instance_variable_set(:@persistable_path, path) }
        end
      end

      # @example Remember the last successful save location
      #   class Settings < Hash
      #     include Hashie::Extensions::MergeInitializer
      #     include Hashie::Extensions::Persistable
      #   end
      #   file = Tempfile.new(['hashie-example', '.yaml'], Dir.pwd)
      #   begin
      #     settings = Settings.new('theme' => 'dark')
      #     settings.persistable_path # => nil
      #     settings.save(file.path)
      #     settings.persistable_path # => File.expand_path(file.path)
      #   ensure
      #     file.close!
      #   end
      attr_reader :persistable_path

      # @example Save again without repeating the path
      #   class Settings < Hash
      #     include Hashie::Extensions::MergeInitializer
      #     include Hashie::Extensions::Persistable
      #   end
      #   file = Tempfile.new(['hashie-example', '.yaml'], Dir.pwd)
      #   begin
      #     settings = Settings.new('theme' => 'dark')
      #     settings.save(file.path)
      #     settings['theme'] = 'light'
      #     settings.save
      #     Settings.load(file.path)['theme'] # => 'light'
      #   ensure
      #     file.close!
      #   end
      def save(path = persistable_path)
        raise ArgumentError, 'a persistence path is required' if path.nil?

        path = File.expand_path(File.path(path))
        yaml = Psych.dump(_persistable_data(self))
        Tempfile.create(['.hashie-', '.yaml'], File.dirname(path)) do |file|
          file.chmod(File.stat(path).mode & 0o777) if File.exist?(path)
          file.write(yaml)
          file.flush
          file.fsync
          file.close
          File.rename(file.path, path)
        end
        @persistable_path = path
      end

      private

      def _persistable_data(value, ancestors = [])
        raise ArgumentError, 'cannot persist cyclic data' if ancestors.any? { |ancestor| ancestor.equal?(value) }

        case value
        when ::Hash
          value.each_with_object({}) do |(key, child), data|
            raise TypeError, 'persisted hash keys must be strings or symbols' unless key.is_a?(String) || key.is_a?(Symbol)

            data[_persistable_data(key)] = _persistable_data(child, ancestors + [value])
          end
        when ::Array
          value.map { |child| _persistable_data(child, ancestors + [value]) }
        when String
          value.dup
        when Symbol, Integer, Float, TrueClass, FalseClass, NilClass
          value
        else
          raise TypeError, "cannot persist a value of class `#{value.class}`"
        end
      end
    end
  end
end
