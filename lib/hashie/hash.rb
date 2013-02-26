require 'hashie/hash_extensions'

module Hashie
  # A Hashie Hash is simply a Hash that has convenience
  # functions baked in such as stringify_keys that may
  # not be available in all libraries.
  class Hash < ::Hash
    include HashExtensions

    # Converts a mash back to a hash (with stringified keys)
    def self.to_hash(hash)
      out = {}
      hash.keys.each do |k|
        if hash[k].is_a?(Array)
          out[k] ||= []
          hash[k].each do |array_object|
            out[k] << (::Hash === array_object ? to_hash(array_object) : array_object)
          end
        else
          out[k] = ::Hash === hash[k] ? to_hash(hash[k]) : hash[k]
        end
      end
      out
    end

    def to_hash
      self.class.to_hash(self)
    end

    # The C geneartor for the json gem doesn't like mashies
    def to_json(*args)
      to_hash.to_json(*args)
    end
  end
end
