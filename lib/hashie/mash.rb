require 'hashie/hash'

module Hashie
  # Mash allows you to create pseudo-objects that have method-like
  # accessors for hash keys. This is useful for such implementations
  # as an API-accessing library that wants to fake robust objects
  # without the overhead of actually doing so. Think of it as OpenStruct
  # with some additional goodies.
  #
  # A Mash will look at the methods you pass it and perform operations
  # based on the following rules:
  #
  # * No punctuation: Returns the value of the hash for that key, or nil if none exists.
  # * Assignment (<tt>=</tt>): Sets the attribute of the given method name.
  # * Existence (<tt>?</tt>): Returns true or false depending on whether that key has been set.
  # * Bang (<tt>!</tt>): Forces the existence of this key, used for deep Mashes. Think of it as "touch" for mashes.
  # * Under Bang (<tt>_</tt>): Like Bang, but returns a new Mash rather than creating a key.  Used to test existance in deep Mashes.
  #
  # == Basic Example
  #
  #   mash = Mash.new
  #   mash.name? # => false
  #   mash.name = "Bob"
  #   mash.name # => "Bob"
  #   mash.name? # => true
  #
  # == Hash Conversion  Example
  #
  #   hash = {:a => {:b => 23, :d => {:e => "abc"}}, :f => [{:g => 44, :h => 29}, 12]}
  #   mash = Mash.new(hash)
  #   mash.a.b # => 23
  #   mash.a.d.e # => "abc"
  #   mash.f.first.g # => 44
  #   mash.f.last # => 12
  #
  # == Bang Example
  #
  #   mash = Mash.new
  #   mash.author # => nil
  #   mash.author! # => <Mash>
  #
  #   mash = Mash.new
  #   mash.author!.name = "Michael Bleigh"
  #   mash.author # => <Mash name="Michael Bleigh">
  #
  # == Under Bang Example
  #
  #   mash = Mash.new
  #   mash.author # => nil
  #   mash.author_ # => <Mash>
  #   mash.author_.name # => nil
  #
  #   mash = Mash.new
  #   mash.author_.name = "Michael Bleigh"  (assigned to temp object)
  #   mash.author # => <Mash>
  #
  class Mash < Hash
    include Hashie::Extensions::PrettyInspect

    ALLOWED_SUFFIXES = %w(? ! = _)

    def self.load(path, options = {})
      @_mashes ||= new do |h, file_path|
        fail ArgumentError, "The following file doesn't exist: #{file_path}" unless File.file?(file_path)

        parser = options.fetch(:parser) {  Hashie::Extensions::Parsers::YamlErbParser }
        h[file_path] = new(parser.perform(file_path)).freeze
      end
      @_mashes[path]
    end

    def to_module(mash_method_name = :settings)
      mash = self
      Module.new do |m|
        m.send :define_method, mash_method_name.to_sym do
          mash
        end
      end
    end

    alias_method :to_s, :inspect

    # If you pass in an existing hash, it will
    # convert it to a Mash including recursively
    # descending into arrays and hashes, converting
    # them as well.
    def initialize(source_hash = nil, default = nil, &blk)
      deep_update(source_hash) if source_hash
      default ? super(default) : super(&blk)
    end

    class << self; alias_method :[], :new; end

    alias_method :regular_reader, :[]
    alias_method :regular_writer, :[]=

    # Retrieves an attribute set in the Mash. Will convert
    # any key passed in to a string before retrieving.
    def custom_reader(key)
      value = regular_reader(key)
      yield value if block_given?
      value
    end

    # Sets an attribute in the Mash. Key will be converted to
    # a string before it is set, and Hashes will be converted
    # into Mashes for nesting purposes.
    def custom_writer(key, value, convert = true) #:nodoc:
      regular_writer(key, convert ? convert_value(value) : value)
    end

    alias_method :[], :custom_reader
    alias_method :[]=, :custom_writer

    # This is the bang method reader, it will return a new Mash
    # if there isn't a value already assigned to the key requested.
    def initializing_reader(key)
      regular_writer(key, self.class.new) unless key?(key)
      regular_reader(key)
    end

    # This is the under bang method reader, it will return a temporary new Mash
    # if there isn't a value already assigned to the key requested.
    def underbang_reader(key)
      key?(key) ? regular_reader(key) : self.class.new
    end

    alias_method :regular_dup, :dup
    # Duplicates the current mash as a new mash.
    def dup
      self.class.new(self, default)
    end

    alias_method :has_key?, :key?
    alias_method :include?, :key?
    alias_method :member?, :key?

    # Performs a deep_update on a duplicate of the
    # current mash.
    def deep_merge(other_hash, &blk)
      dup.deep_update(other_hash, &blk)
    end
    alias_method :merge, :deep_merge

    # Recursively merges this mash with the passed
    # in hash, merging each hash in the hierarchy.
    def deep_update(other_hash, &blk)
      other_hash.each_pair do |k, v|
        if regular_reader(k).is_a?(Mash) && v.is_a?(::Hash)
          custom_reader(k).deep_update(v, &blk)
        else
          value = convert_value(v, true)
          value = convert_value(blk.call(k, self[k], value), true) if blk
          custom_writer(k, value, false)
        end
      end
      self
    end
    alias_method :deep_merge!, :deep_update
    alias_method :update, :deep_update
    alias_method :merge!, :update

    # Assigns a value to a key
    def assign_property(name, value)
      self[name] = value
    end

    # Performs a shallow_update on a duplicate of the current mash
    def shallow_merge(other_hash)
      dup.shallow_update(other_hash)
    end

    # Merges (non-recursively) the hash from the argument,
    # changing the receiving hash
    def shallow_update(other_hash)
      other_hash.each_pair { |k, v| regular_writer(k, convert_value(v, true)) }
      self
    end

    def replace(other_hash)
      (keys - other_hash.keys).each { |key| delete(key) }
      other_hash.each { |key, value| self[key] = value }
      self
    end

    def respond_to_missing?(method_name, *args)
      return true if key?(method_name)
      _, suffix = method_suffix(method_name)
      case suffix
      when '=', '?', '!', '_'
        return true
      else
        super
      end
    end

    def prefix_method?(method_name)
      method_name = method_name.to_s
      method_name.end_with?(*ALLOWED_SUFFIXES) && key?(method_name.chop)
    end

    def method_missing(method_name, *args, &blk)
      return self.[](method_name, &blk) if key?(method_name)
      return self.[](method_name.to_s, &blk) if key?(method_name.to_s)

      name, suffix = method_suffix(method_name)
      case suffix
      when '='
        assign_property(name, args.first)
      when '?'
        !!self[name]
      when '!'
        initializing_reader(name)
      when '_'
        underbang_reader(name)
      else
        default(method_name)
      end
    end

    protected

    def method_suffix(method_name)
      suffixes_regex = ALLOWED_SUFFIXES.join
      match = method_name.to_s.match(/(.*?)([#{suffixes_regex}]?)$/)
      [convert_key(match[1], method_name), match[2]]
    end

    def convert_key(transformed_value, original_value)
      case original_value
      when Symbol
        transformed_value.to_sym
      when String
        transformed_value.to_s
      end
    end

    def convert_value(val, duping = false) #:nodoc:
      case val
      when self.class
        val.dup
      when Hash
        duping ? val.dup : val
      when ::Hash
        val = val.dup if duping
        self.class.new(val)
      when Array
        val.map { |e| convert_value(e) }
      else
        val
      end
    end
  end
end
