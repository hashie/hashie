# frozen_string_literal: true

require 'hashie/hash'
require 'hashie/array'
require 'hashie/utils'
require 'hashie/logger'
require 'hashie/extensions/key_conflict_warning'

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
  # * Truthiness (<tt>?</tt>): Returns true or false depending on the truthiness of
  #   the attribute, or false if the key is not set.
  # * Bang (<tt>!</tt>): Forces the existence of this key, used for deep Mashes. Think of it
  #   as "touch" for mashes.
  # * Under Bang (<tt>_</tt>): Like Bang, but returns a new Mash rather than creating a key.
  #   Used to test existence in deep Mashes.
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
  # @example Read nested hashes through method access
  #   mash = Hashie::Mash.new(author: { name: 'Ada' })
  #   mash.author.name # => 'Ada'
  #   mash.missing? # => false
  class Mash < Hash
    extend Hashie::Extensions::KeyConflictWarning

    ALLOWED_SUFFIXES = %w[? ! = _].freeze

    # Loads a YAML file. The default parser evaluates ERB templates, so only
    # use this default with trusted files. Pass YamlParser to avoid ERB.
    #
    # @example Load and cache a frozen configuration from a YAML file
    #   require 'tempfile'
    #   file = Tempfile.new(['hashie-example', '.yml'], Dir.pwd)
    #   begin
    #     file.write("name: Ada\n")
    #     file.close
    #     settings = Hashie::Mash.load(file.path, parser: Hashie::Extensions::Parsers::YamlParser)
    #     settings.name # => 'Ada'
    #     settings.frozen? # => true
    #     File.write(file.path, "name: Grace\n")
    #     Hashie::Mash.load(file.path).to_hash # => { 'name' => 'Ada' }
    #   ensure
    #     file.close!
    #   end
    def self.load(path, options = {})
      @_mashes ||= new

      return @_mashes[path] if @_mashes.key?(path)
      raise ArgumentError, "file not found: `#{path}`" unless File.file?(path)

      options = options.dup
      parser = options.delete(:parser) { Hashie::Extensions::Parsers::YamlErbParser }
      @_mashes[path] = new(parser.perform(path, options)).freeze
    end

    # @example Expose a Mash from an included module
    #   settings = Hashie::Mash.new(name: 'Ada')
    #   klass = Class.new { include settings.to_module(:configuration) }
    #   klass.new.configuration.name # => 'Ada'
    def to_module(mash_method_name = :settings)
      mash = self
      Module.new do |m|
        m.send :define_method, mash_method_name.to_sym do
          mash
        end
      end
    end

    # @example Generate real methods for existing keys
    #   mash = Hashie::Mash.new(name: 'Ada')
    #   mash.with_accessors!
    #   mash.name # => 'Ada'
    #   mash.method(:name).owner.instance_methods(false).include?(:name) # => true
    def with_accessors!
      extend Hashie::Extensions::Mash::DefineAccessors
    end

    # @example Inspect the Mash's attributes
    #   Hashie::Mash.new(name: 'Ada').to_s # => '#<Hashie::Mash name="Ada">'
    alias to_s inspect

    # If you pass in an existing hash, it will
    # convert it to a Mash including recursively
    # descending into arrays and hashes, converting
    # them as well.
    #
    # @example Recursively convert hashes nested in arrays
    #   mash = Hashie::Mash.new(users: [{ name: 'Ada' }])
    #   mash.users.first.name # => 'Ada'
    #   mash.users.class # => Hashie::Array
    def initialize(source_hash = nil, default = nil, &blk)
      deep_update(source_hash) if source_hash
      default ? super(default) : super(&blk)
    end

    # Creates a new anonymous subclass with key conflict
    # warnings disabled. You may pass an array of method
    # symbols to restrict the disabled warnings to.
    # Hashie::Mash.quiet.new(hash) all warnings disabled.
    # Hashie::Mash.quiet(:zip).new(hash) only zip warning
    # is disabled.
    #
    # @example Disable warnings for a conflicting key on a subclass
    #   klass = Hashie::Mash.quiet(:zip)
    #   klass.new(zip: '12345')[:zip] # => '12345'
    #   klass.disable_warnings?(:zip) # => true
    def self.quiet(*method_keys)
      @memoized_classes ||= {}
      @memoized_classes[method_keys] ||= Class.new(self) do
        disable_warnings(*method_keys)
      end
    end

    class << self
      # @example Construct a Mash with bracket notation
      #   Hashie::Mash[name: 'Ada'].name # => 'Ada'
      alias [] new
    end

    # @example Read stored string keys without key conversion
    #   mash = Hashie::Mash.new(name: 'Ada')
    #   mash.regular_reader('name') # => 'Ada'
    #   mash.regular_reader(:name) # => nil
    alias regular_reader []

    # @example Store a value without recursively converting it
    #   mash = Hashie::Mash.new
    #   mash.regular_writer('user', { name: 'Ada' })
    #   mash['user'].class # => Hash
    #   mash['user'] # => { name: 'Ada' }
    alias regular_writer []=

    # Retrieves an attribute set in the Mash. Will convert a key passed in
    # as a symbol to a string before retrieving.
    #
    # @example Read a symbol key and yield the result
    #   mash = Hashie::Mash.new(name: 'Ada')
    #   observed = []
    #   mash.custom_reader(:name) { |value| observed << value } # => 'Ada'
    #   observed # => ['Ada']
    def custom_reader(key)
      default_proc.call(self, key) if default_proc && !key?(key)
      value = regular_reader(convert_key(key))
      yield value if block_given?
      value
    end

    # Sets an attribute in the Mash. Symbol keys will be converted to
    # strings before being set, and Hashes will be converted into Mashes
    # for nesting purposes.
    #
    # @example Normalize assigned keys and recursively convert values
    #   mash = Hashie::Mash.new
    #   mash.custom_writer(:user, { name: 'Ada' })
    #   mash.keys # => ['user']
    #   mash.user.name # => 'Ada'
    def custom_writer(key, value, convert = true) # :nodoc:
      log_built_in_message(key) if key.respond_to?(:to_sym) && log_collision?(key.to_sym)
      regular_writer(convert_key(key), convert ? convert_value(value) : value)
    end

    # @example Read symbol and string keys interchangeably
    #   mash = Hashie::Mash.new(name: 'Ada')
    #   mash[:name] # => 'Ada'
    #   mash['name'] # => 'Ada'
    alias [] custom_reader

    # @example Convert assigned hashes to nested Mashes
    #   mash = Hashie::Mash.new
    #   mash[:user] = { name: 'Ada' }
    #   mash.user.name # => 'Ada'
    alias []= custom_writer

    # This is the bang method reader, it will return a new Mash
    # if there isn't a value already assigned to the key requested.
    #
    # @example Persist an initially empty nested Mash
    #   mash = Hashie::Mash.new
    #   mash.initializing_reader(:user).name = 'Ada'
    #   mash.user.name # => 'Ada'
    def initializing_reader(key)
      ck = convert_key(key)
      regular_writer(ck, self.class.new) unless key?(ck)
      regular_reader(ck)
    end

    # This is the under bang method reader, it will return a temporary new Mash
    # if there isn't a value already assigned to the key requested.
    #
    # @example Read an absent branch without storing it
    #   mash = Hashie::Mash.new
    #   mash.underbang_reader(:user).empty? # => true
    #   mash.key?(:user) # => false
    def underbang_reader(key)
      ck = convert_key(key)
      if key?(ck)
        regular_reader(ck)
      else
        self.class.new
      end
    end

    # @example Fetch symbol keys and supply a fallback for missing keys
    #   mash = Hashie::Mash.new(name: 'Ada')
    #   mash.fetch(:name) # => 'Ada'
    #   mash.fetch(:missing, 'unknown') # => 'unknown'
    def fetch(key, *args)
      super(convert_key(key), *args)
    end

    # @example Delete a string-backed key using a symbol
    #   mash = Hashie::Mash.new(name: 'Ada')
    #   mash.delete(:name) # => 'Ada'
    #   mash.empty? # => true
    def delete(key)
      super(convert_key(key))
    end

    # @example Retrieve multiple keys using either key form
    #   Hashie::Mash.new(name: 'Ada', age: 36).values_at(:name, 'age', :missing) # => ['Ada', 36, nil]
    def values_at(*keys)
      super(*keys.map { |key| convert_key(key) })
    end

    # Returns a new instance of the class it was called on, using its keys as
    # values, and its values as keys. The new values and keys will always be
    # strings.
    #
    # @example Swap keys and values while retaining Mash behavior
    #   inverted = Hashie::Mash.new(name: :author).invert
    #   inverted.author # => 'name'
    #   inverted.class # => Hashie::Mash
    def invert
      self.class.new(super)
    end

    # Returns a new instance of the class it was called on, containing elements
    # for which the given block returns false.
    #
    # @example Remove selected entries from a copy
    #   mash = Hashie::Mash.new(name: 'Ada', age: 36)
    #   mash.reject { |key, _value| key == 'age' }.to_hash # => { 'name' => 'Ada' }
    #   mash.age # => 36
    def reject(&blk)
      self.class.new(super)
    end

    # Returns a new instance of the class it was called on, containing elements
    # for which the given block returns true.
    #
    # @example Keep matching entries in a new Mash
    #   selected = Hashie::Mash.new(name: 'Ada', age: 36).select { |key, _value| key == 'name' }
    #   selected.name # => 'Ada'
    #   selected.key?(:age) # => false
    def select(&blk)
      self.class.new(super)
    end

    # @example Make a shallow copy using the original Hash duplication
    #   mash = Hashie::Mash.new(user: { name: 'Ada' })
    #   copy = mash.regular_dup
    #   copy.equal?(mash) # => false
    #   copy.user.equal?(mash.user) # => true
    alias regular_dup dup

    # Hash's own readers, since a key like "default" can override them.
    HASH_DEFAULT = ::Hash.instance_method(:default)
    HASH_DEFAULT_PROC = ::Hash.instance_method(:default_proc)
    private_constant :HASH_DEFAULT, :HASH_DEFAULT_PROC

    # Duplicates the current mash as a new mash.
    #
    # @example Duplicate nested Mashes independently
    #   mash = Hashie::Mash.new(user: { name: 'Ada' })
    #   copy = mash.dup
    #   copy.user.name = 'Grace'
    #   mash.user.name # => 'Ada'
    #   copy.user.name # => 'Grace'
    def dup
      default = HASH_DEFAULT.bind_call(self)
      default_proc = HASH_DEFAULT_PROC.bind_call(self)
      self.class.new(self, default, &default_proc)
    end

    # @example Check the exact stored key without symbol conversion
    #   mash = Hashie::Mash.new(name: 'Ada')
    #   mash.regular_key?('name') # => true
    #   mash.regular_key?(:name) # => false
    alias regular_key? key?

    # @example Recognize symbol and string versions of a key
    #   mash = Hashie::Mash.new(name: nil)
    #   mash.key?(:name) # => true
    #   mash.key?('name') # => true
    def key?(key)
      super(convert_key(key))
    end
    # @example Test key presence even for a nil value
    #   Hashie::Mash.new(name: nil).has_key?(:name) # => true
    alias has_key? key?

    # @example Test membership with a symbol key
    #   Hashie::Mash.new(name: 'Ada').include?(:name) # => true
    alias include? key?

    # @example Test membership with a string key
    #   Hashie::Mash.new(name: 'Ada').member?('name') # => true
    alias member? key?

    # Performs a deep_update on a duplicate of the
    # current mash.
    #
    # @example Recursively merge without modifying the receiver
    #   mash = Hashie::Mash.new(user: { name: 'Ada' })
    #   merged = mash.deep_merge(user: { age: 36 })
    #   merged.user.to_hash # => { 'name' => 'Ada', 'age' => 36 }
    #   mash.user.key?(:age) # => false
    def deep_merge(*other_hashes, &blk)
      dup.deep_update(*other_hashes, &blk)
    end

    # Recursively merges this mash with the passed
    # in hash, merging each hash in the hierarchy.
    #
    # @example Update nested values in place with conflict resolution
    #   mash = Hashie::Mash.new(user: { visits: 2 })
    #   mash.deep_update(user: { visits: 3 }) { |_key, old, new| old + new }
    #   mash.user.visits # => 5
    def deep_update(*other_hashes, &blk)
      other_hashes.each do |other_hash|
        _deep_update(other_hash, &blk)
      end
      self
    end

    # Alias these lexically so they get the correctly defined
    # #deep_merge and #deep_update based on ruby version.
    #
    # @example Merge nested hashes into a copy
    #   mash = Hashie::Mash.new(user: { name: 'Ada' })
    #   mash.merge(user: { age: 36 }).user.to_hash # => { 'name' => 'Ada', 'age' => 36 }
    alias merge deep_merge

    # @example Recursively merge into the receiver
    #   mash = Hashie::Mash.new(user: { name: 'Ada' })
    #   mash.deep_merge!(user: { age: 36 })
    #   mash.user.to_hash # => { 'name' => 'Ada', 'age' => 36 }
    alias deep_merge! deep_update

    # @example Update the receiver with nested keys
    #   mash = Hashie::Mash.new(user: { name: 'Ada' })
    #   mash.update(user: { age: 36 })
    #   mash.user.age # => 36
    #   mash.user.name # => 'Ada'
    alias update deep_update

    # @example Merge multiple hashes into the receiver
    #   mash = Hashie::Mash.new
    #   mash.merge!({ name: 'Ada' }, { age: 36 })
    #   mash.to_hash # => { 'name' => 'Ada', 'age' => 36 }
    alias merge! update

    def _deep_update(other_hash, &blk)
      other_hash.each_pair do |k, v|
        key = convert_key(k)
        if v.is_a?(::Hash) && key?(key) && regular_reader(key).is_a?(Mash)
          custom_reader(key).deep_update(v, &blk)
        else
          value = convert_value(v, true)
          value = convert_value(yield(key, self[k], value), true) if blk && key?(k)
          custom_writer(key, value, false)
        end
      end
    end
    private :_deep_update

    # Assigns a value to a key
    #
    # @example Assign a property by name
    #   mash = Hashie::Mash.new
    #   mash.assign_property(:name, 'Ada')
    #   mash.name # => 'Ada'
    def assign_property(name, value)
      self[name] = value
    end

    # Performs a shallow_update on a duplicate of the current mash
    #
    # @example Replace a nested hash in a copy rather than merging it
    #   mash = Hashie::Mash.new(user: { name: 'Ada', age: 36 })
    #   mash.shallow_merge(user: { name: 'Grace' }).user.to_hash # => { 'name' => 'Grace' }
    #   mash.user.age # => 36
    def shallow_merge(other_hash)
      dup.shallow_update(other_hash)
    end

    # Merges (non-recursively) the hash from the argument,
    # changing the receiving hash
    #
    # @example Replace a nested value in place
    #   mash = Hashie::Mash.new(user: { name: 'Ada', age: 36 })
    #   mash.shallow_update(user: { name: 'Grace' })
    #   mash.user.to_hash # => { 'name' => 'Grace' }
    def shallow_update(other_hash)
      other_hash.each_pair do |k, v|
        regular_writer(convert_key(k), convert_value(v, true))
      end
      self
    end

    # @example Discard omitted attributes and convert replacement keys
    #   mash = Hashie::Mash.new(name: 'Ada', age: 36)
    #   mash.replace(name: 'Grace')
    #   mash.to_hash # => { 'name' => 'Grace' }
    def replace(other_hash)
      (keys - other_hash.keys).each { |key| delete(key) }
      other_hash.each { |key, value| self[key] = value }
      self
    end

    # @example Discover dynamic readers and suffix methods
    #   mash = Hashie::Mash.new(name: 'Ada')
    #   mash.respond_to?(:name) # => true
    #   mash.respond_to?(:missing) # => false
    #   mash.respond_to?(:missing!) # => true
    def respond_to_missing?(method_name, *args)
      return true if key?(method_name)

      suffix = method_suffix(method_name)
      if suffix
        true
      else
        super
      end
    end

    # @example Recognize suffix methods for existing keys
    #   mash = Hashie::Mash.new(name: 'Ada')
    #   mash.prefix_method?(:name?) # => true
    #   mash.prefix_method?(:missing?) # => false
    def prefix_method?(method_name)
      method_name = method_name.to_s
      method_name.end_with?(*ALLOWED_SUFFIXES) && key?(method_name.chop)
    end

    # @example Use dynamic assignment, queries, and nested initialization
    #   mash = Hashie::Mash.new
    #   mash.user!.name = 'Ada'
    #   mash.user.name # => 'Ada'
    #   mash.user? # => true
    #   mash.missing_.empty? # => true
    #   mash.key?(:missing) # => false
    def method_missing(method_name, *args, &blk)
      return self.[](method_name, &blk) if key?(method_name)

      name, suffix = method_name_and_suffix(method_name)
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
        self[method_name]
      end
    end

    # play nice with ActiveSupport Array#extract_options!
    #
    # @example Identify a Mash as eligible for options extraction
    #   Hashie::Mash.new(name: 'Ada').extractable_options? # => true
    def extractable_options?
      true
    end

    # another ActiveSupport method, see issue #270
    #
    # @example Supply defaults without overwriting existing values
    #   mash = Hashie::Mash.new(name: 'Ada')
    #   mash.reverse_merge(name: 'Grace', active: true).to_hash # => { 'name' => 'Ada', 'active' => true }
    def reverse_merge(other_hash)
      self.class.new(other_hash).merge(self)
    end

    # @example Traverse nested Mashes with symbol keys
    #   mash = Hashie::Mash.new(user: { name: 'Ada' })
    #   mash.dig(:user, :name) # => 'Ada'
    #   mash.dig(:missing, :name) # => nil
    def dig(*keys)
      super(*keys.map { |key| convert_key(key) })
    end

    # @example Transform values into a new Mash
    #   transformed = Hashie::Mash.new(visits: 2).transform_values { |value| value * 3 }
    #   transformed.visits # => 6
    #   transformed.class # => Hashie::Mash
    def transform_values(&blk)
      self.class.new(super)
    end

    # Returns a new instance of the class it was called on, with nil values
    # removed.
    #
    # @example Remove nils while preserving false
    #   Hashie::Mash.new(name: nil, active: false).compact.to_hash # => { 'active' => false }
    def compact
      self.class.new(super)
    end

    # @example Select keys with either symbol or string names
    #   Hashie::Mash.new(name: 'Ada', age: 36).slice(:name).to_hash # => { 'name' => 'Ada' }
    def slice(*keys)
      string_keys = keys.map { |key| convert_key(key) }
      self.class.new(super(*string_keys))
    end

    # @example Transform keys into a new Mash
    #   transformed = Hashie::Mash.new(name: 'Ada').transform_keys(&:upcase)
    #   transformed['NAME'] # => 'Ada'
    #   transformed.class # => Hashie::Mash
    def transform_keys(&blk)
      self.class.new(super)
    end

    # @example Exclude symbol keys from a copy
    #   mash = Hashie::Mash.new(name: 'Ada', age: 36)
    #   mash.except(:age).to_hash # => { 'name' => 'Ada' }
    #   mash.age # => 36
    def except(*keys)
      string_keys = keys.map { |key| convert_key(key) }
      self.class.new(super(*string_keys))
    end

    protected

    def method_name_and_suffix(method_name)
      method_name = method_name.to_s
      if method_name.end_with?(*ALLOWED_SUFFIXES)
        [method_name[0..-2], method_name[-1]]
      else
        [method_name, nil]
      end
    end

    def method_suffix(method_name)
      method_name = method_name.to_s
      method_name[-1] if method_name.end_with?(*ALLOWED_SUFFIXES)
    end

    # Symbol#name returns the symbol's interned frozen string, where
    # Symbol#to_s allocates a new one on every read and write.
    def convert_key(key) # :nodoc:
      return key.name if key.is_a?(Symbol)

      key.respond_to?(:to_sym) ? key.to_s : key
    end

    def convert_value(val, duping = false) # :nodoc:
      case val
      when self.class
        val.dup
      when Hash
        duping ? val.dup : val
      when ::Hash
        val = val.dup if duping
        self.class.new(val)
      when ::Array
        Array.new(val.length) { |index| convert_value(val[index]) }
      else
        val
      end
    end

    private

    def log_built_in_message(method_key)
      return if self.class.disable_warnings?(method_key)

      method_information = Hashie::Utils.method_information(method(method_key))

      Hashie.logger.warn(
        'You are setting a key that conflicts with a built-in method ' \
        "#{self.class}##{method_key} #{method_information}. " \
        'This can cause unexpected behavior when accessing the key as a ' \
        'property. You can still access the key via the #[] method.'
      )
    end

    def log_collision?(method_key)
      return false unless method_key.is_a?(String) || method_key.is_a?(Symbol)
      return false unless respond_to?(method_key)

      _, suffix = method_name_and_suffix(method_key)

      (!suffix || suffix == '=') &&
        !self.class.disable_warnings?(method_key) &&
        !(regular_key?(method_key) || regular_key?(method_key.to_s))
    end
  end
end
