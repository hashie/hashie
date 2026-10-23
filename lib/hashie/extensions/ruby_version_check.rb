# frozen_string_literal: true

require 'hashie/extensions/ruby_version'

module Hashie
  module Extensions
    # @example Conditionally run code for the current Ruby
    #   klass = Class.new { include Hashie::Extensions::RubyVersionCheck }
    #   klass.with_minimum_ruby(RUBY_VERSION) { 'supported' } # => 'supported'
    module RubyVersionCheck
      def self.included(base)
        base.extend ClassMethods
      end

      # @example Add version checks to a class
      #   klass = Class.new { include Hashie::Extensions::RubyVersionCheck }
      #   klass.with_minimum_ruby?('0.0.0') # => true
      #   klass.with_minimum_ruby?('999.0.0') # => false
      module ClassMethods
        # @example Run the block only when the minimum is satisfied
        #   klass = Class.new { include Hashie::Extensions::RubyVersionCheck }
        #   klass.with_minimum_ruby('0.0.0') { 'supported' } # => 'supported'
        #   klass.with_minimum_ruby('999.0.0') { raise 'not reached' } # => nil
        def with_minimum_ruby(version)
          yield if with_minimum_ruby?(version)
        end

        # @example Accept the current version as a minimum
        #   klass = Class.new { include Hashie::Extensions::RubyVersionCheck }
        #   klass.with_minimum_ruby?(RUBY_VERSION) # => true
        #   klass.with_minimum_ruby?('999.0.0') # => false
        def with_minimum_ruby?(version)
          RubyVersion.new(RUBY_VERSION) >= RubyVersion.new(version)
        end
      end
    end
  end
end
