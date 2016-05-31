module Hashie
  module Extensions
    module RubyVersionCheck
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def with_minimum_ruby(version)
          yield if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new(version)
        end
      end
    end
  end
end
