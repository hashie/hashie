# frozen_string_literal: true

module Hashie
  module Extensions
    # Builds nested hashes through blocks without changing ordinary method access.
    # Include after MethodAccess when using a Hash subclass.
    #
    #   class Configuration < Hashie::Mash
    #     include Hashie::Extensions::BlockAccess
    #   end
    #
    #   config = Configuration.new
    #   config.author { |author| author.name = 'Michael Bleigh' }
    #   config.author.name # => 'Michael Bleigh'
    module BlockAccess
      def [](key)
        return super unless block_given?

        value = block_access_child(self, key)
        yield value
        value
      end

      # A block-only builder does not make a missing reader available to respond_to?.
      def method_missing(name, *args, &block) # rubocop:disable Style/MissingRespondToMissing
        return super unless block && !name.to_s.end_with?('=', '?', '!', '_')

        raise ArgumentError, "wrong number of arguments (given `#{args.size}`, expected 0..1)" if args.size > 1

        child = block_access_child(self, block_access_key(name))
        child = block_access_child(child, args.first) unless args.empty?
        block.call(child)
        child
      end

      private

      def block_access_key(name)
        return name if key?(name)
        return name.to_s if key?(name.to_s)

        respond_to?(:convert_key, true) ? convert_key(name.to_s) : name.to_s
      end

      def block_access_child(parent, key)
        parent[key] = parent.class.new unless parent.key?(key)
        child = parent[key]
        return child if child.is_a?(::Hash)

        raise TypeError, "key `#{key}` already contains a `#{child.class}`"
      end
    end
  end
end
