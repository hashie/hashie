# frozen_string_literal: true

module Hashie
  module Extensions
    module Array
      # Formats array inspection with the concrete class name.
      #
      # @example
      #   klass = Class.new(Array) do
      #     include Hashie::Extensions::Array::PrettyInspect
      #   end
      #   array = klass.new([1, 'two'])
      #   array.inspect # => "#<#{klass} [1, \"two\"]>"
      module PrettyInspect
        # @example Retain the original inspection as array_inspect
        #   klass = Class.new(Array) do
        #     include Hashie::Extensions::Array::PrettyInspect
        #   end
        #   klass.new([1, 2]).array_inspect # => '[1, 2]'
        def self.included(base)
          base.send :alias_method, :array_inspect, :inspect
          base.send :alias_method, :inspect, :hashie_inspect
        end

        # @example
        #   klass = Class.new(Array) do
        #     include Hashie::Extensions::Array::PrettyInspect
        #   end
        #   klass.new([1, 2]).hashie_inspect # => "#<#{klass} [1, 2]>"
        def hashie_inspect
          ret = "#<#{self.class} ["
          ret << to_a.map(&:inspect).join(', ')
          ret << ']>'
          ret
        end
      end
    end
  end
end
