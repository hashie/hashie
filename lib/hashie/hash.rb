require 'hashie/hash_extensions'

module Hashie
  # A Hashie Hash is simply a Hash that has convenience
  # functions baked in such as stringify_keys that may
  # not be available in all libraries.
  class Hash < ::Hash
    include HashExtensions

    # Converts a mash back to a hash (with stringified or symbolized keys)
    def to_hash(options = {})
      out = {}
      keys.each do |k|
        assignment_key = k.to_s
        assignment_key = assignment_key.to_sym if options[:symbolize_keys]
        if self[k].is_a?(Array)
          out[assignment_key] ||= []
          self[k].each do |array_object|
            out[assignment_key] << (Hash === array_object ? array_object.to_hash(options) : array_object)
          end
        else
          out[assignment_key] = Hash === self[k] ? self[k].to_hash(options) : self[k]
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
