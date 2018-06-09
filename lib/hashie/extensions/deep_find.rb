module Hashie
  module Extensions
    # Extends a Hash with the ability to find a key within a deeply nested child
    #
    # The searching performed by this module is always a depth-first search. It
    # also traverses collections within nested values of an array, e.g., when a
    # nested key contains an array of hashes, the hashes within the array will
    # also be searched.
    #
    # @example Create a new type of hash with this searching capability
    #   class Response < Hash
    #     include Hashie::Extensions::DeepFind
    #   end
    #
    #   response = Response.new
    #   response[:users] =  [
    #     {location: {address: "123 Easy St."}},
    #     {location: {address: "234 Easy St."}}
    #   ]
    #   response.deep_find(:address)  #=> "123 Easy St."
    #   response.deep_find_all(:address)  #=> ["123 Easy St.", "234 Easy St."]
    #
    # @example Find the first occurrence of a key in a pre-existing hash
    #   response = {user: {location: {address: "123 Easy St."}}}
    #   response.extend(Hashie::Extensions::DeepFind)
    #   response.deep_find(:address) # => "123 Easy St."
    #
    # @example Find all occurences of a key in a pre-existing hash
    #   response = {users: [
    #     {location: {address: "123 Easy St."}},
    #     {location: {address: "234 Easy St."}}
    #   ]}
    #   response.extend(Hashie::Extensions::DeepFind)
    #   response.deep_find_all(:address) # => ["123 Easy St.", "234 Easy St."]
    module DeepFind
      # Find a deeply nested key with a depth-first search
      #
      # @example Extends a pre-existing hash with this capability
      #   response = {user: {location: {address: "123 Easy St."}}}
      #   response.extend(Hashie::Extensions::DeepFind)
      #   response.deep_find(:address) # => "123 Easy St."
      #
      # @example Creates a new class of hash with this capability
      #   class SearchableHash < Hash
      #     include Hashie::Extensions::DeepFind
      #   end
      #
      #   hash = SearchableHash.new
      #   hash[:user] = {location: {address: "123 Easy St."}}
      #   hash.deep_find(:address) # => "123 Easy St."
      #
      # @api public
      # @param [String, Symbol] key the key to find in the nested hash
      # @return [Object, nil] the value at the first occurrence of a key or
      #   nil when the key does not exist
      def deep_find(key)
        _deep_find(key)
      end

      # !@method deep_detect(key)
      #   @see {deep_find}
      alias_method :deep_detect, :deep_find

      # Finds all occurrences of a key with a depth-first search
      #
      # @example Build a searchable hash class with this capability
      #   class SearchableHash < Hash
      #     include Hashie::Extensions::DeepFind
      #   end
      #
      #   hash = SearchableHash.new
      #   hash[:users] = [
      #     {location: {address: '123 Easy St.'}},
      #     {location: {address: '234 Easy St.'}}
      #   ]
      #   hash.deep_find_all(:address) # => ["123 Easy St.", "234 Easy St."]
      #
      # @example Extends a pre-existing hash with this capability
      #   response = {users: [
      #     {location: {address: "123 Easy St."}},
      #     {location: {address: "234 Easy St."}}
      #   ]}
      #   response.extend(Hashie::Extensions::DeepFind)
      #   response.deep_find_all(:address) # => ["123 Easy St.", "234 Easy St."]
      #
      # @api public
      # @param [String, Symbol] key the key to find all occurrences of
      # @return [Array, nil] an array of all matching values or nil when
      #   the key does not exist
      def deep_find_all(key)
        matches = _deep_find_all(key)
        matches.empty? ? nil : matches
      end

      # !@method deep_select(key)
      #   @see {deep_find_all}
      alias_method :deep_select, :deep_find_all

      private

      # Helper method for finding the first occurrence of a key
      #
      # @api private
      # @param [String, Symbol] key the key to search for
      # @param [Hash] object the object to search
      # @return [Object, nil]
      def _deep_find(key, object = self)
        _deep_find_all(key, object).first
      end

      # Helper method for finding all occurrences of a key
      #
      # @api private
      # @param [String, Symbol] key the key to search for
      # @param [Hash] object the object to search
      # @param [Array] matches the previous matches from the object
      # @return [Array]
      def _deep_find_all(key, object = self, matches = [])
        deep_locate_result = Hashie::Extensions::DeepLocate.deep_locate(key, object).tap do |result|
          result.map! { |element| element[key] }
        end

        matches.concat(deep_locate_result)
      end
    end
  end
end
