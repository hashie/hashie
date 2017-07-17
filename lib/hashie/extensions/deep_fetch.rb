module Hashie
  module Extensions
    # Extends a Hash with the ability to fetch from a deeply nested child
    #
    # @example Build a response object with this capability
    #   class Response < Hash
    #     include Hashie::Extensions::DeepFetch
    #   end
    #
    #   response = Response.new
    #   response.merge!(user: {location: {address: "123 Easy St."}})
    #   response.deep_fetch(:user, :location, :address)  #=> "123 Easy St."
    #   response.deep_fetch(:user, :location, :country)
    #   #=> raise Hashie::Extensions::DeepFetch::UndefinedPathError, "Could not fetch path (user > location > country) at country"
    #   response.deep_fetch(:user, :location, :country) { "Unknown" }
    #   #=> "Unknown"
    #
    # @example Extends a pre-existing object with this capability
    #   tweet = {content: "Hello, world", author: {username: "mdo"}}
    #   tweet.extend(Hashie::Extensions::DeepFetch)
    #   tweet.deep_fetch(:author, :username)  #=> "mdo"
    #   tweet.deep_fetch(:author, :username, :id)
    #   #=> raise Hashie::Extensions::DeepFetch::UndefinedPathError, "Could not fetch path (author > username > id) at id"
    #   tweet.deep_fetch(:author)
    #   #=> {username: "mdo"}
    #
    # If a block is provided its value will be returned if the key does not exist.
    #
    #  options.deep_fetch(:user, :non_existent_key) { 'a value' } #=> 'a value'
    #
    # This is particularly useful for fetching values from deeply nested api responses or params hashes.
    module DeepFetch
      # Raised when a deep path doesn't exist in a nested hash
      class UndefinedPathError < StandardError; end

      # Walks down a path in a deeply nested hash to fetch a value
      #
      # @example Fetches the user's address in a nested hash
      #   response = {user: {location: {address: "123 Easy St."}}}
      #   response.extend(Hashie::Extensions::DeepFetch)
      #   response.deep_fetch(:user, :location, :address)  #=> "123 Easy St."
      #
      # @example Fetches the user's country with a default in a nested hash
      #   response = {user: {location: {address: "123 Easy St."}}}
      #   response.extend(Hashie::Extensions::DeepFetch)
      #   response.deep_fetch(:user, :location, :address, :country) { "Unknown" }
      #   #=> "Unknown"
      #
      # @api public
      # @param [Array] args the deep path to read
      # @yield [key] Specifies a default value if the path does not exist
      # @yieldparam [String, Symbol] key the path segment that did not exist
      # @return [Object] the value that exists at the specified deep path
      # @raise [UndefinedPathError] when the path does not exist in the hash
      #   and no default block was specified
      def deep_fetch(*args, &block)
        args.reduce(self) do |obj, arg|
          begin
            arg = Integer(arg) if obj.is_a? Array
            obj.fetch(arg)
          rescue ArgumentError, IndexError, NoMethodError => e
            break block.call(arg) if block
            raise UndefinedPathError, "Could not fetch path (#{args.join(' > ')}) at #{arg}", e.backtrace
          end
        end
      end
    end
  end
end
