require 'hashie/hash_extensions'

module Hashie
  # A Hashie Hash is simply a Hash that has convenience
  # functions baked in such as stringify_keys that may
  # not be available in all libraries.
  class Hash < ::Hash
    include HashExtensions

    # Converts a mash back to a hash (with stringified keys)
    def to_hash(options={})
      out = {}
      keys.each do |k|
        if self[k].is_a?(Array)
          k = options[:symbolize_keys] ? k.to_sym : k.to_s
          out[k] ||= []
          self[k].each do |array_object|
            out[k] << (Hash === array_object ? array_object.to_hash : array_object)
          end
        else
          k = options[:symbolize_keys] ? k.to_sym : k.to_s
          out[k] = Hash === self[k] ? self[k].to_hash : self[k]
        end
      end
      out
    end

    # The C geneartor for the json gem doesn't like mashies
    def to_json(*args)
      to_hash.to_json(*args)
    end
  end
end
