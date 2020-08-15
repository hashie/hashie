# frozen_string_literal: true

require 'hashie/extensions/deep_locate'
module Hashie
  module Extensions
    module DeepGrep
      # Performs a depth-first search on deeply nested data structures for
      # keys or values that match the given pattern and returns all matching
      # occurrences.
      #
      #  options = {
      #    users: [
      #      { location: { address: '123 Street' } },
      #      { location: { address: '234 Street' } }
      #    ]
      #  }
      #  options.extend(Hashie::Extensions::DeepGrep)
      #  options.deep_grep(/Street/) # => [{:address: '123 Street'}, {:address: '234 Street'}]
      #  options.deep_grep(/address/) # => [{:address: '123 Street'}, {:address: '234 Street'}]
      #
      #  class MyHash < Hash
      #    include Hashie::Extensions::DeepGrep
      #  end
      #
      #  my_hash = MyHash.new
      #  my_hash[:users] = [
      #    { location: { address: '123 Street' } },
      #    { location: { address: '234 Street' } }
      #  ]
      #  my_hash.deep_grep(/Street/) # => [{:address: '123 Street'}, {:address: '234 Street'}]
      #  my_hash.deep_grep(/address/) # => [{:address: '123 Street'}, {:address: '234 Street'}]
      def deep_grep(pattern)
        matches = _deep_grep(pattern)
        matches.empty? ? nil : matches
      end

      private

      def _match_text?(pattern, text)
        return false unless text.instance_of?(String) || text.instance_of?(Symbol)

        !pattern.match(text).nil?
      end

      def _deep_grep(pattern, object = self, matches = [])
        grep_result = DeepLocate.deep_locate(lambda do |key, value, _object|
          _match_text?(pattern, key) || _match_text?(pattern, value)
        end, object)

        matches.concat(grep_result)
      end
    end
  end
end
