# frozen_string_literal: true

require 'hashie/extensions/deep_locate'
module Hashie
  module Extensions
    # @example Find values in nested collections
    #   hash = { users: [{ name: 'Ada' }] }.extend(Hashie::Extensions::DeepFind)
    #   hash.deep_find(:name) # => 'Ada'
    module DeepFind
      # Performs a depth-first search on deeply nested data structures for
      # a key and returns the first occurrence of the key.
      #
      #  options = {user: {location: {address: '123 Street'}}}
      #  options.extend(Hashie::Extensions::DeepFind)
      #  options.deep_find(:address) # => '123 Street'
      #
      #  class MyHash < Hash
      #    include Hashie::Extensions::DeepFind
      #  end
      #
      #  my_hash = MyHash.new
      #  my_hash[:user] = {location: {address: '123 Street'}}
      #  my_hash.deep_find(:address) # => '123 Street'
      #
      # @example Return the first value
      #   hash = { users: [{ name: 'Ada' }, { name: 'Grace' }] }.extend(Hashie::Extensions::DeepFind)
      #   hash.deep_find(:name) # => 'Ada'
      def deep_find(key)
        _deep_find(key)
      end

      # @example Detect the first nested value
      #   hash = { user: { name: 'Ada' } }.extend(Hashie::Extensions::DeepFind)
      #   hash.deep_detect(:name) # => 'Ada'
      alias deep_detect deep_find

      # Performs a depth-first search on deeply nested data structures for
      # a key and returns all occurrences of the key.
      #
      #  options = {
      #    users: [
      #      { location: {address: '123 Street'} },
      #      { location: {address: '234 Street'}}
      #    ]
      #  }
      #  options.extend(Hashie::Extensions::DeepFind)
      #  options.deep_find_all(:address) # => ['123 Street', '234 Street']
      #
      #  class MyHash < Hash
      #    include Hashie::Extensions::DeepFind
      #  end
      #
      #  my_hash = MyHash.new
      #  my_hash[:users] = [
      #    {location: {address: '123 Street'}},
      #    {location: {address: '234 Street'}}
      #  ]
      #  my_hash.deep_find_all(:address) # => ['123 Street', '234 Street']
      #
      # @example Collect all values, or nil if absent
      #   hash = { users: [{ name: 'Ada' }, { name: 'Grace' }] }.extend(Hashie::Extensions::DeepFind)
      #   hash.deep_find_all(:name) # => ['Ada', 'Grace']
      #   hash.deep_find_all(:email) # => nil
      def deep_find_all(key)
        matches = _deep_find_all(key)
        matches.empty? ? nil : matches
      end

      # @example Select every nested value
      #   hash = { users: [{ name: 'Ada' }, { name: 'Grace' }] }.extend(Hashie::Extensions::DeepFind)
      #   hash.deep_select(:name) # => ['Ada', 'Grace']
      alias deep_select deep_find_all

      private

      def _deep_find(key, object = self)
        _deep_find_all(key, object).first
      end

      def _deep_find_all(key, object = self, matches = [])
        deep_locate_result = DeepLocate.deep_locate(key, object).tap do |result|
          result.map! { |element| element[key] }
        end

        matches.concat(deep_locate_result)
      end
    end
  end
end
