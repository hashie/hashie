# frozen_string_literal: true

require 'psych'
require 'tempfile'

module Hashie
  module Extensions
    # Opt-in YAML file persistence for classes initialized from a hash.
    module Persistable
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def load(path)
          path = File.expand_path(File.path(path))
          data = Psych.safe_load(File.read(path), permitted_classes: [Symbol], aliases: false)
          raise TypeError, 'persisted YAML must contain a hash' unless data.is_a?(::Hash)

          new(data).tap { |object| object.instance_variable_set(:@persistable_path, path) }
        end
      end

      attr_reader :persistable_path

      def save(path = persistable_path)
        raise ArgumentError, 'a persistence path is required' if path.nil?

        path = File.expand_path(File.path(path))
        yaml = Psych.dump(persistable_data(self))
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

      def persistable_data(value, ancestors = [])
        raise ArgumentError, 'cannot persist cyclic data' if ancestors.any? { |ancestor| ancestor.equal?(value) }

        case value
        when ::Hash
          value.each_with_object({}) do |(key, child), data|
            raise TypeError, 'persisted hash keys must be strings or symbols' unless key.is_a?(String) || key.is_a?(Symbol)

            data[persistable_data(key)] = persistable_data(child, ancestors + [value])
          end
        when ::Array
          value.map { |child| persistable_data(child, ancestors + [value]) }
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
