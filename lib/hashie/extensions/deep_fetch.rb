# frozen_string_literal: true

module Hashie
  module Extensions
    # Searches a deeply nested datastructure for a key path, and returns the associated value.
    #
    #  options = { user: { location: { address: '123 Street' } } }
    #  options.deep_fetch :user, :location, :address #=> '123 Street'
    #
    # If a block is provided its value will be returned if the key does not exist.
    #
    #  options.deep_fetch(:user, :non_existent_key) { 'a value' } #=> 'a value'
    #
    # This is particularly useful for fetching values from deeply nested api responses
    #   or params hashes.
    #
    # @example Traverse hashes and arrays
    #   hash = { users: [{ name: 'Ada' }] }.extend(Hashie::Extensions::DeepFetch)
    #   hash.deep_fetch(:users, 0, :name) # => 'Ada'
    module DeepFetch
      # @example Report an undefined path
      #   error = Hashie::Extensions::DeepFetch::UndefinedPathError.new('missing address')
      #   error.message # => 'missing address'
      class UndefinedPathError < StandardError; end

      # @example Use a fallback for a missing path
      #   hash = { user: {} }.extend(Hashie::Extensions::DeepFetch)
      #   hash.deep_fetch(:user, :name) { |key| "missing #{key}" } # => 'missing name'
      #   hash.deep_fetch(:user) # => {}
      def deep_fetch(*args, &block)
        args.reduce(self) do |obj, arg|
          arg = Integer(arg) if obj.is_a? Array
          obj.fetch(arg)
        rescue ArgumentError, IndexError, NoMethodError => e
          break yield(arg) if block

          raise UndefinedPathError,
                "could not fetch path (`#{args.join(' > ')}`) at `#{arg}`", e.backtrace
        end
      end
    end
  end
end
