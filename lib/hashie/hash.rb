# frozen_string_literal: true

require 'hashie/extensions/stringify_keys'
require 'hashie/extensions/pretty_inspect'

module Hashie
  # A Hashie Hash is simply a Hash that has convenience
  # functions baked in such as stringify_keys that may
  # not be available in all libraries.
  #
  # @example Convert keys using the built-in extensions
  #   Hashie::Hash[name: 'Ada'].stringify_keys # => { 'name' => 'Ada' }
  class Hash < ::Hash
    include Hashie::Extensions::PrettyInspect
    include Hashie::Extensions::StringifyKeys

    # Convert this hash into a Mash
    #
    # @example Read converted data through methods
    #   Hashie::Hash[name: 'Ada'].to_mash.name # => 'Ada'
    def to_mash
      ::Hashie::Mash.new(self)
    end

    # Converts a mash back to a hash (with stringified or symbolized keys)
    #
    # @example Recursively convert nested hashes and their keys
    #   hash = Hashie::Hash[user: Hashie::Hash[name: 'Ada']]
    #   hash.to_hash(stringify_keys: true) # => { 'user' => { 'name' => 'Ada' } }
    def to_hash(options = {})
      out = {}
      each_key do |k|
        assignment_key =
          if options[:stringify_keys]
            k.to_s
          elsif options[:symbolize_keys] && k.respond_to?(:to_sym)
            k.to_sym
          else
            k
          end
        if self[k].is_a?(Array)
          out[assignment_key] ||= []
          self[k].each do |array_object|
            out[assignment_key] << _maybe_convert_to_hash(array_object, options)
          end
        else
          out[assignment_key] = _maybe_convert_to_hash(self[k], options)
        end
      end
      out
    end

    # The C generator for the json gem doesn't like mashies
    #
    # @example Serialize as an ordinary JSON object
    #   require 'json'
    #   JSON.parse(Hashie::Hash[name: 'Ada'].to_json) # => { 'name' => 'Ada' }
    def to_json(*args)
      to_hash.to_json(*args)
    end

    private

    def _maybe_convert_to_hash(object, options)
      return object unless object.is_a?(Hash) || object.respond_to?(:to_hash)

      _flexibly_convert_to_hash(object, options)
    end

    def _flexibly_convert_to_hash(object, options = {})
      if object.method(:to_hash).arity.zero?
        object.to_hash
      else
        object.to_hash(options)
      end
    end
  end
end
