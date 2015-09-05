  module Hashie
    module Extensions
      module Persistable
        CANNOT_INCLUDE = 'Peristable can only be used on classes with Hashie::Extensions::HashInitializer'
        CANNOT_SAVE = 'Cannot save unless persistable_file is set or the target file is passed as a parameter'

        module ClassMethods
          def load(file)
            new(YAML.load(File.read(file))).tap do |h|
              h.persistable_file = file
            end
          end
        end

        def self.included(base)
          # Can only include into classes with a hash initializer
          fail ArgumentError, CANNOT_INCLUDE unless
            base.include?(Hashie::Extensions::HashInitializer) ||
            base.include?(Hashie::Extensions::MergeInitializer)
          base.extend ClassMethods
          super
        end

        def save(file = nil)
          self.persistable_file = file unless file.nil?
          fail ArgumentError, CANNOT_SAVE if persistable_file.nil?
          File.write(persistable_file, YAML.dump(self))
          persistable_file
        end

        def persistable_file=(file)
          @persistable_file = Pathname(file)
        end

        attr_reader :persistable_file
      end
    end
  end
