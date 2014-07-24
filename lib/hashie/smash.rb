require 'hashie/mash'

module Hashie
  # Smash, or "safe Mash," is a Mash with method protection. It affords all of
  # the basic functionality of a Mash, but prevents you from attempting to
  # overwrite its functions with attributes.
  #
  # Smash allows you to create pseudo-objects that have method-like
  # accessors for hash keys. This is useful for such implementations
  # as an API-accessing library that wants to fake robust objects
  # without the overhead of actually doing so. Think of it as OpenStruct
  # with some additional goodies.
  #
  # A Smash will look at the methods you pass it and perform operations
  # based on the following rules:
  #
  # * No punctuation: Returns the value of the hash for that key, or nil if none exists.
  # * Assignment (<tt>=</tt>): Sets the attribute of the given method name.
  # * Existence (<tt>?</tt>): Returns true or false depending on whether that key has been set.
  # * Bang (<tt>!</tt>): Forces the existence of this key, used for deep Mashes. Think of it as "touch" for smashes.
  # * Under Bang (<tt>_</tt>): Like Bang, but returns a new Smash rather than creating a key.  Used to test existence in deep Smashes.
  #
  # == Basic Example
  #
  #   smash = Smash.new
  #   smash.name? # => false
  #   smash.name = "Bob"
  #   smash.name # => "Bob"
  #   smash.name? # => true
  #
  # == Hash Conversion  Example
  #
  #   hash = {:a => {:b => 23, :d => {:e => "abc"}}, :f => [{:g => 44, :h => 29}, 12]}
  #   smash = Smash.new(hash)
  #   smash.a.b # => 23
  #   smash.a.d.e # => "abc"
  #   smash.f.first.g # => 44
  #   smash.f.last # => 12
  #
  # == Bang Example
  #
  #   smash = Smash.new
  #   smash.author # => nil
  #   smash.author! # => <Smash>
  #
  #   smash = Smash.new
  #   smash.author!.name = "Michael Bleigh"
  #   smash.author # => <Smash name="Michael Bleigh">
  #
  # == Under Bang Example
  #
  #   smash = Smash.new
  #   smash.author # => nil
  #   smash.author_ # => <Smash>
  #   smash.author_.name # => nil
  #
  #   smash = Smash.new
  #   smash.author_.name = "Michael Bleigh"  (assigned to temp object)
  #   smash.author # => <Smash>
  #
  # If you attempt to overwrite one of the Smash methods, it will raise an
  # ArgumentError.
  #
  # == Method Overwriting Example
  #
  #   smash = Smash.new
  #   smash.zip = '10001' # => ArgumentError: You cannot overwrite a hash method (zip)
  #   smash.zip # => []
  #   smash.hash_zip # => []
  class Smash < Mash
    def custom_writer(key, value, convert = true) #:nodoc:
      fail ArgumentError, "You cannot overwrite a hash method (#{key})" if hash_method?(key)

      regular_writer(key, convert ? convert_value(value) : value)
    end
    alias_method :[]=, :custom_writer

    protected

    def hash_method?(method_name)
      method_list = methods.map { |method| method.to_s }

      method_list.include?(method_name.to_s.sub('hash_', '')) ||
      method_list.include?(method_name.to_s)
    end
  end
end
