# frozen_string_literal: true

module Hashie
  module Extensions
    # SRP: This extension will fail an error whenever a key is accessed
    #   that does not exist in the hash.
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
    # NOTE: For googlers coming from Python to Ruby, this extension makes a Hash
    # behave more like a "Dictionary".
    #
    # @example Raise on missing keys
    #   hash = { name: 'Ada' }.extend(Hashie::Extensions::StrictKeyAccess)
    #   hash[:name] # => 'Ada'
    #   expect { hash[:missing] }.to raise_error(KeyError)
    module StrictKeyAccess
      # @example Explain why defaults are unsupported
      #   error = Hashie::Extensions::StrictKeyAccess::DefaultError.new
      #   error.message # => 'Setting or using a default with Hashie::Extensions::StrictKeyAccess does not make sense'
      class DefaultError < StandardError
        # @example Construct a default-access error
        #   error = Hashie::Extensions::StrictKeyAccess::DefaultError.new
        #   error.message # => 'Setting or using a default with Hashie::Extensions::StrictKeyAccess does not make sense'
        def initialize
          super('Setting or using a default with Hashie::Extensions::StrictKeyAccess ' \
                'does not make sense'
          )
        end
      end

      # NOTE: Defaults don't make any sense with a StrictKeyAccess.
      # NOTE: When key lookup fails a KeyError is raised.
      #
      # Normal:
      #
      #     >> a = Hash.new(123)
      #     => {}
      #     >> a["noes"]
      #     => 123
      #
      # With StrictKeyAccess:
      #
      #     >> a = StrictKeyAccessHash.new(123)
      #     => {}
      #     >> a["noes"]
      #       KeyError: key not found: "noes"
      #
      # @example Fetch an existing value without a default fallback
      #   hash = { name: 'Ada' }.extend(Hashie::Extensions::StrictKeyAccess)
      #   hash[:name] # => 'Ada'
      #   expect { hash[:missing] }.to raise_error(KeyError)
      def [](key)
        fetch(key)
      end

      # @example Reject reading the default value
      #   hash = {}.extend(Hashie::Extensions::StrictKeyAccess)
      #   error_class = begin
      #     hash.default
      #   rescue Hashie::Extensions::StrictKeyAccess::DefaultError => error
      #     error.class
      #   end
      #   error_class # => Hashie::Extensions::StrictKeyAccess::DefaultError
      def default(_ = nil)
        raise DefaultError
      end

      # @example Reject assigning a default value
      #   hash = {}.extend(Hashie::Extensions::StrictKeyAccess)
      #   rejected = begin
      #     hash.default = 'unknown'
      #     false
      #   rescue Hashie::Extensions::StrictKeyAccess::DefaultError
      #     true
      #   end
      #   rejected # => true
      def default=(_)
        raise DefaultError
      end

      # @example Reject reading a default proc
      #   hash = {}.extend(Hashie::Extensions::StrictKeyAccess)
      #   rejected = begin
      #     hash.default_proc
      #     false
      #   rescue Hashie::Extensions::StrictKeyAccess::DefaultError
      #     true
      #   end
      #   rejected # => true
      def default_proc
        raise DefaultError
      end

      # @example Reject assigning a default proc
      #   hash = {}.extend(Hashie::Extensions::StrictKeyAccess)
      #   rejected = begin
      #     hash.default_proc = ->(_hash, _key) { 'unknown' }
      #     false
      #   rescue Hashie::Extensions::StrictKeyAccess::DefaultError
      #     true
      #   end
      #   rejected # => true
      def default_proc=(_)
        raise DefaultError
      end

      # @example Find an existing key and reject missing values
      #   hash = { name: 'Ada', nil => false }.extend(Hashie::Extensions::StrictKeyAccess)
      #   hash.key('Ada') # => :name
      #   hash.key(false) # => nil
      #   expect { hash.key('Grace') }.to raise_error(KeyError)
      def key(value)
        super.tap do |result|
          raise KeyError, "no key found for value `#{value.inspect}`" if result.nil? && (!key?(result) || self[result] != value)
        end
      end
    end
  end
end
