# frozen_string_literal: true

require 'hashie/extensions/array/pretty_inspect'

module Hashie
  # An array with readable inspection and string-index digging.
  #
  # @example Build a Hashie array
  #   Hashie::Array[10, 20].dig('1') # => 20
  class Array < ::Array
    include Hashie::Extensions::Array::PrettyInspect

    # @example Accept string indexes when traversing nested arrays
    #   Hashie::Array[Hashie::Array['first', 'second']].dig('0', '1') # => 'second'
    def dig(*indexes)
      converted_indexes = indexes.map do |idx|
        Integer(idx)
      rescue ArgumentError
        idx
      end
      super(*converted_indexes)
    end
  end
end
