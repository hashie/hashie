module Hashie
  module Extensions
    # SRP: This extension will fail an error whenever a key is accessed that does not exist in the hash.
    #
    #   EXAMPLE:
    #
    #     class StrictKeyAccessHash < Hash
    #       include Hashie::Extensions::StrictKeyAccess
    #     end
    #
    #     >> hash = StrictKeyAccessHash[foo: "bar"]
    #     => {:foo=>"bar"}
    #     >> hash[:foo]
    #     => "bar"
    #     >> hash[:cow]
    #       KeyError: key not found: :cow
    #
    # NOTE: For googlers coming from Python to Ruby, this extension makes a Hash behave like a "Dictionary".
    #
    module StrictKeyAccess
      class DefaultError < StandardError
        def initialize(msg = 'Setting or using a default with Hashie::Extensions::StrictKeyAccess does not make sense', *args)
          super
        end
      end

      # NOTE: This extension would break the default behavior of Hash initialization:
      #
      #     >> a = StrictKeyAccessHash.new(a: :b)
      #     => {}
      #     >> a[:a]
      #       KeyError: key not found: :a
      #
      # Includes the Hashie::Extensions::MergeInitializer extension to get around that problem.
      # Also note that defaults still don't make any sense with a StrictKeyAccess.
      def self.included(base)
        # Can only include into classes with a hash initializer
        base.send(:include, Hashie::Extensions::MergeInitializer)
      end

      def [](key)
        fetch(key)
      end

      def default(_ = nil)
        fail DefaultError
      end

      def default=(_)
        fail DefaultError
      end

      def default_proc
        fail DefaultError
      end

      def default_proc=(_)
        fail DefaultError
      end

      def key(value)
        result = super
        if result.nil? && (!key?(result) || self[result] != value)
          fail KeyError, "key not found with value of #{value.inspect}"
        else
          result
        end
      end
    end
  end
end
