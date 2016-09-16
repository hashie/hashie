require 'hashie/extensions/array/pretty_inspect'
require 'hashie/extensions/ruby_version_check'

module Hashie
  class Array < ::Array
    include Hashie::Extensions::Array::PrettyInspect
    include Hashie::Extensions::RubyVersionCheck
    with_minimum_ruby('2.3.0') do
      def dig(*indexes)
        super(*indexes.map { |idx| Integer(idx) })
      end
    end
  end
end
