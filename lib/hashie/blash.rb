require 'hashie/hash'

module Hashie
  # Blash allows you to create Mash-like objects with a block syntax
  # for creating nested hashes. This is useful for building deeply
  # nested configuration hashes, similar in style to many dsl based
  # configuration files.
  #
  # A Blash will look at the methods you pass it and perform operations
  # based on the following rules:
  #
  # * No punctuation: Returns the value of the hash for that key, or nil if none exists.
  # * With Block (<tt>{...}</tt>): Sets key to and yields a new blash
  # * Assignment (<tt>=</tt>): Sets the attribute of the given method name.
  # * Existence (<tt>?</tt>): Returns true or false depending on whether that key has been set.
  #
  # == Basic Example
  #
  #   blash = Blash.new
  #   blash.name? # => false
  #   blash.name = "Bob"
  #   blash.name # => "Bob"
  #   blash.name? # => true
  #
  # == Hash Conversion  Example
  #
  #   hash = {:a => {:b => 23, :d => {:e => "abc"}}, :f => [{:g => 44, :h => 29}, 12]}
  #   blash = Blash.new(hash)
  #   blash.a.b # => 23
  #   blash.a.d.e # => "abc"
  #   blash.f.first.g # => 44
  #   blash.f.last # => 12
  #
  # == Block Example
  #
  #   blash = Blash.new
  #   blash.author do |a|
  #     a.name = "Michael Bleigh"
  #   end
  #   blash.author # => <Blash name="Michael Bleigh">
  #   blash.author.name # => "Michael Bleigh"
  #
  class Blash < Hash
    include Hashie::PrettyInspect
    alias_method :to_s, :inspect

    # If you pass in an existing hash, it will
    # convert it to a Blash including recursively
    # descending into arrays and hashes, converting
    # them as well.
    def initialize(source_hash = nil, default = nil, &blk)
      deep_update(source_hash) if source_hash
      default ? super(default) : super(&blk)
    end

    class << self; alias [] new; end

    def id #:nodoc:
      self["id"]
    end

    def type #:nodoc:
      self["type"]
    end

    alias_method :regular_reader, :[]
    alias_method :regular_writer, :[]=

    # Retrieves an attribute set in the Blash. Will convert
    # any key passed in to a string before retrieving.
    def custom_reader(key)
      value = regular_reader(convert_key(key))
      yield value if block_given?
      value
    end

    # Sets an attribute in the Blash. Key will be converted to
    # a string before it is set, and Hashes will be converted
    # into Blashes for nesting purposes.
    def custom_writer(key,value) #:nodoc:
      regular_writer(convert_key(key), convert_value(value))
    end

    alias_method :[], :custom_reader
    alias_method :[]=, :custom_writer

    # This is the bang method reader, it will return a new Blash
    # if there isn't a value already assigned to the key requested.
    def initializing_reader(key)
      ck = convert_key(key)
      regular_writer(ck, self.class.new) unless key?(ck)
      regular_reader(ck)
    end

    def fetch(key, *args)
      super(convert_key(key), *args)
    end

    def delete(key)
      super(convert_key(key))
    end

    alias_method :regular_dup, :dup
    # Duplicates the current blash as a new blash.
    def dup
      self.class.new(self, self.default)
    end

    def key?(key)
      super(convert_key(key))
    end
    alias_method :has_key?, :key?
    alias_method :include?, :key?
    alias_method :member?, :key?

    # Performs a deep_update on a duplicate of the
    # current blash.
    def deep_merge(other_hash, &blk)
      dup.deep_update(other_hash, &blk)
    end
    alias_method :merge, :deep_merge

    # Recursively merges this blash with the passed
    # in hash, merging each hash in the hierarchy.
    def deep_update(other_hash, &blk)
      other_hash.each_pair do |k,v|
        key = convert_key(k)
        if regular_reader(key).is_a?(Blash) and v.is_a?(::Hash)
          custom_reader(key).deep_update(v, &blk)
        else
          value = convert_value(v, true)
          value = blk.call(key, self[k], value) if blk
          custom_writer(key, value)
        end
      end
      self
    end
    alias_method :deep_merge!, :deep_update
    alias_method :update, :deep_update
    alias_method :merge!, :update

    # Performs a shallow_update on a duplicate of the current blash
    def shallow_merge(other_hash)
      dup.shallow_update(other_hash)
    end

    # Merges (non-recursively) the hash from the argument,
    # changing the receiving hash
    def shallow_update(other_hash)
      other_hash.each_pair do |k,v|
        regular_writer(convert_key(k), convert_value(v, true))
      end
      self
    end

    def replace(other_hash)
      (keys - other_hash.keys).each { |key| delete(key) }
      other_hash.each { |key, value| self[key] = value }
      self
    end

    # Will return true if the Blash has had a key
    # set in addition to normal respond_to? functionality.
    def respond_to?(method_name, include_private=false)
      return true if key?(method_name) || method_name.to_s.slice(/[=?]\Z/)
      super
    end

    def method_missing(method_name, *args, &blk)
      match = method_name.to_s.match(/(.*?)([?=]?)$/)

      if block_given?
        super unless match[2].empty?

        raise ArgumentError, "wrong number of arguments (#{args.size} for 0)" if args.size > 1

        if key?(method_name) && ! self.[](method_name).is_a?(Blash)
          raise TypeError, "key '#{method_name}' already contains a #{self.[](method_name).class}"
        end

        val = self.[](method_name) || initializing_reader(method_name)

        yield val

        return val
      else
        if key?(method_name)
          raise ArgumentError, "wrong number of arguments (#{args.size} for 0)" unless args.empty?
          return self.[](method_name, &blk)
        end

        case match[2]
        when "="
          raise ArgumentError, "wrong number of arguments (#{args.size} for 1)" unless args.size == 1
          self[match[1]] = args.first
        when "?"
          raise ArgumentError, "wrong number of arguments (#{args.size} for 0)" unless args.empty?
          !!self[match[1]]
        when ""
          raise ArgumentError, "wrong number of arguments (#{args.size} for 0)" unless args.empty?
          default(method_name)
        else
          super
        end
      end
    end

    protected

    def convert_key(key) #:nodoc:
      key.to_s
    end

    def convert_value(val, duping=false) #:nodoc:
      case val
        when self.class
          val.dup
        when Hash
          duping ? val.dup : val
        when ::Hash
          val = val.dup if duping
          self.class.new(val)
        when Array
          val.collect{ |e| convert_value(e) }
        else
          val
      end
    end
  end
end
