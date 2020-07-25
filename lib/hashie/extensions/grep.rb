require 'hashie/extensions/deep_locate'
module Hashie
  module Extensions
    module Grep
      # Performs a depth-first search on deeply nested data structures for
      # a key and returns all occurrences of the key.
      #
      #  options = {
      #    users: [
      #      { location: {address: '123 Street'} },
      #      { location: {address: '234 Street'}}
      #    ]
      #  }
      #  options.extend(Hashie::Extensions::Grep)
      #  options.grep(/Street/) # => [{:address: '123 Street'}, {:address: '234 Street'}]
      #
      #  class MyHash < Hash
      #    include Hashie::Extensions::Grep
      #  end
      #
      #  my_hash = MyHash.new
      #  my_hash[:users] = [
      #    {location: {address: '123 Street'}},
      #    {location: {address: '234 Street'}}
      #  ]
      #  my_hash.grep(/Street/) # => [{:address: '123 Street'}, {:address: '234 Street'}]
      def grep(pattern)
        matches = _grep(pattern)
        matches.empty? ? nil : matches
      end

      private

      def _match_text?(pattern, text)
        return false unless (text.instance_of?(String) || text.instance_of?(Symbol))

        !pattern.match(text).nil?
      end

      def _grep(pattern, object = self, matches = [])
        grep_result = DeepLocate.deep_locate -> (key, value, object) { 
          _match_text?(pattern, key) || _match_text?(pattern, value)
        }, object

        matches.concat(grep_result)
      end
    end
  end
end
