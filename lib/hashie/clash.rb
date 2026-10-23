# frozen_string_literal: true

require 'hashie/hash'

module Hashie
  #
  # A Clash is a "Chainable Lazy Hash". Inspired by libraries such as Arel,
  # a Clash allows you to chain together method arguments to build a
  # hash, something that's especially useful if you're doing something
  # like constructing a complex options hash. Here's a basic example:
  #
  #     c = Hashie::Clash.new.conditions(:foo => 'bar').order(:created_at)
  #     c # => {:conditions => {:foo => 'bar'}, :order => :created_at}
  #
  # Clash provides another way to create sub-hashes by using bang notation.
  # You can dive into a sub-hash by providing a key with a bang and dive
  # back out again with the _end! method. Example:
  #
  #     c = Hashie::Clash.new.conditions!.foo('bar').baz(123)._end!.order(:created_at)
  #     c # => { conditions: { foo: 'bar', baz: 123 }, order: :created_at}
  #
  # Because the primary functionality of Clash is to build options objects,
  # all keys are converted to symbols since many libraries expect symbols explicitly
  # for keys.
  #
  # @example Build an options hash through chained calls
  #   options = Hashie::Clash.new.conditions!.active(true)._end!.limit(10)
  #   options # => { conditions: { active: true }, limit: 10 }
  class Clash < ::Hash
    # Raised when bang chaining encounters a value that is not a hash.
    #
    # @example Reject chaining into a scalar
    #   error = begin
    #     Hashie::Clash.new(limit: 10).limit!
    #   rescue Hashie::Clash::ChainError => exception
    #     exception
    #   end
    #   error.class # => Hashie::Clash::ChainError
    #   error.message # => 'tried to chain into a non-hash key'
    class ChainError < ::StandardError; end
    # The parent Clash if this Clash was created via chaining.
    #
    # @example Find the containing options hash
    #   root = Hashie::Clash.new
    #   root.conditions!._parent.equal?(root) # => true
    attr_reader :_parent

    # Initialize a new clash by passing in a Hash to
    # convert and, optionally, the parent to which this
    # Clash is chained.
    #
    # @example Normalize initial keys to symbols
    #   Hashie::Clash.new('limit' => 10) # => { limit: 10 }
    def initialize(other_hash = {}, parent = nil)
      @_parent = parent
      other_hash.each_pair do |k, v|
        self[k.to_sym] = v
      end
    end

    # Jump back up a level if you are using bang method
    # chaining. For example:
    #
    # c = Hashie::Clash.new.foo('bar')
    # c.baz!.foo(123) # => c[:baz]
    # c.baz!._end! # => c
    #
    # @example Continue building the parent hash
    #   Hashie::Clash.new.conditions!.active(true)._end!.limit(10) # => { conditions: { active: true }, limit: 10 }
    def _end!
      _parent
    end

    # @example Serialize a Clash through YAML's encoding callback
    #   require 'yaml'
    #   options = Hashie::Clash.new.limit(10)
    #   YAML.unsafe_load(YAML.dump(options)) # => { limit: 10 }
    def encode_with(coder)
      coder['hash'] = to_h
      coder['parent'] = _parent
    end

    # @example Restore a chained Clash through YAML's loading callback
    #   require 'yaml'
    #   root = Hashie::Clash.new.conditions!.active(true)._end!
    #   restored = YAML.unsafe_load(YAML.dump(root))
    #   restored[:conditions]._parent.equal?(restored) # => true
    def init_with(coder)
      initialize(coder['hash'], coder['parent'])
    end

    # @example Build an id option without colliding with object identity
    #   Hashie::Clash.new.id(42) # => { id: 42 }
    def id(*args) # :nodoc:
      method_missing(:id, *args)
    end

    # @example Merge repeated hash options through chained builder calls
    #   Hashie::Clash.new.conditions(active: true).conditions(role: 'admin') # => { conditions: { active: true, role: 'admin' } }
    def _merge_store(key, *args) # :nodoc:
      case args.length
      when 1
        val = args.first
        val = self.class.new(self[key]).merge(val) if self[key].is_a?(::Hash) && val.is_a?(::Hash)
      else
        val = args
      end

      self[key.to_sym] = val
      self
    end
    private :_merge_store

    # @example Build nested options with dynamic method names
    #   Hashie::Clash.new.conditions!.active(true)._end!.limit(10) # => { conditions: { active: true }, limit: 10 }
    def method_missing(name, *args) # :nodoc:
      if args.empty? && name.to_s.end_with?('!')
        key = name[0...-1].to_sym

        case self[key]
        when NilClass
          self[key] = self.class.new({}, self)
        when Clash
          self[key]
        when Hash
          self[key] = self.class.new(self[key], self)
        else
          raise ChainError, 'tried to chain into a non-hash key'
        end
      elsif args.any?
        _merge_store(name, *args)
      else
        super
      end
    end

    # @example Discover supported builder calls
    #   options = Hashie::Clash.new(limit: 10)
    #   options.respond_to?(:conditions!) # => true
    #   options.respond_to?(:limit!) # => false
    #   options.respond_to?(:order) # => true
    def respond_to_missing?(method_name, _include_private = false)
      method_name = method_name.to_s
      return super if %w[marshal_dump marshal_load _dump _load].include?(method_name)

      if method_name.end_with?('!')
        key = method_name[0...-1].to_sym
        [NilClass, Clash, Hash].include?(self[key].class)
      else
        true
      end
    end
  end
end
