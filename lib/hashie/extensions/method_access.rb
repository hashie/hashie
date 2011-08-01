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
      def respond_to?(name)
        return true if key?(name.to_s) || key?(name.to_sym)
        super
      end
      def method_missing(name, *args)
        return self[name.to_s] if key?(name.to_s)
        return self[name.to_sym] if key?(name.to_sym)
        super
      end
    end

    module MethodWriter
      def method_missing(name, *args)

      end
    end

    module MethodQuery
      def method_missing(name, *args)

      end
    end

    module MethodAccess
      def self.included(base)
        [MethodReader, MethodWriter, MethodQuery].each do |mod|
          base.send :include, mod
        end
      end
    end
  end
end
