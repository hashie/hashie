module Hashie
  module Extensions
    # MethodReader allows you to access keys of the hash
    # via method calls. This gives you an OStruct like way
    # to access your hash's keys. It will recognize keys
    # either as strings or symbols.
    #
    # Note that while nil keys will be returned as nil,
    # undefined keys will raise NoMethodErrors. Also note that
    # #respond_to? has been patched to appropriately recognize
    # key methods.
    #
    # @example
    #   class User < Hash
    #     include Hashie::Extensions::MethodReader
    #   end
    #
    #   user = User.new
    #   user['first_name'] = 'Michael'
    #   user.first_name # => 'Michael'
    #
    #   user[:last_name] = 'Bleigh'
    #   user.last_name # => 'Bleigh'
    #
    #   user[:birthday] = nil
    #   user.birthday # => nil
    #
    #   user.not_declared # => NoMethodError
    module MethodReader
      def respond_to?(name, include_private = false)
        return true if key?(name.to_s) || key?(name.to_sym)
        super
      end

      def method_missing(name, *args)
        return self[name.to_s] if key?(name.to_s)
        return self[name.to_sym] if key?(name.to_sym)
        super
      end
    end

    # MethodWriter gives you #key_name= shortcuts for
    # writing to your hash. Keys are written as strings,
    # override #convert_key if you would like to have symbols
    # or something else.
    #
    # Note that MethodWriter also overrides #respond_to such
    # that any #method_name= will respond appropriately as true.
    #
    # @example
    #   class MyHash < Hash
    #     include Hashie::Extensions::MethodWriter
    #   end
    #
    #   h = MyHash.new
    #   h.awesome = 'sauce'
    #   h['awesome'] # => 'sauce'
    #
    module MethodWriter
      def respond_to?(name, include_private = false)
        return true if name.to_s =~ /=$/
        super
      end

      def method_missing(name, *args)
        if args.size == 1 && name.to_s =~ /(.*)=$/
          return self[convert_key(Regexp.last_match[1])] = args.first
        end

        super
      end

      def convert_key(key)
        key.to_s
      end
    end

    # MethodQuery gives you the ability to check for the truthiness
    # of a key via method calls. Note that it will return false if
    # the key is set to a non-truthful value, not if the key isn't
    # set at all. Use #key? for checking if a key has been set.
    #
    # MethodQuery will check against both string and symbol names
    # of the method for existing keys. It also patches #respond_to
    # to appropriately detect the query methods.
    #
    # @example
    #   class MyHash < Hash
    #     include Hashie::Extensions::MethodQuery
    #   end
    #
    #   h = MyHash.new
    #   h['abc'] = 123
    #   h.abc? # => true
    #   h['def'] = nil
    #   h.def? # => false
    #   h.hji? # => NoMethodError
    module MethodQuery
      def respond_to?(name, include_private = false)
        return true if name.to_s =~ /(.*)\?$/ && (key?(Regexp.last_match[1]) || key?(Regexp.last_match[1].to_sym))
        super
      end

      def method_missing(name, *args)
        if args.empty? && name.to_s =~ /(.*)\?$/ && (key?(Regexp.last_match[1]) || key?(Regexp.last_match[1].to_sym))
          return self[Regexp.last_match[1]] || self[Regexp.last_match[1].to_sym]
        end

        super
      end
    end

    # A macro module that will automatically include MethodReader,
    # MethodWriter, and MethodQuery, giving you the ability to read,
    # write, and query keys in a hash using method call shortcuts.
    module MethodAccess
      def self.included(base)
        [MethodReader, MethodWriter, MethodQuery].each do |mod|
          base.send :include, mod
        end
      end
    end
  end
end
