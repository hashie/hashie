# frozen_string_literal: true

require 'hashie/extensions/array/pretty_inspect'

module Hashie
  class Array < ::Array
    include Hashie::Extensions::Array::PrettyInspect

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
