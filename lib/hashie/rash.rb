module Hashie
  #
  # Rash is a Hash whose keys can be Regexps, or Ranges, which will
  # match many input keys.
  #
  # A good use case for this class is routing URLs in a web framework.
  # The Rash's keys match URL patterns, and the values specify actions
  # which can handle the URL. When the Rash's value is proc, the proc
  # will be automatically called with the regexp's matched groups as
  # block arguments.
  #
  # Usage example:
  #
  #     greeting = Hashie::Rash.new( /^Mr./ => "Hello sir!", /^Mrs./ => "Evening, madame." )
  #     greeting["Mr. Steve Austin"] #=> "Hello sir!"
  #     greeting["Mrs. Steve Austin"] #=> "Evening, madame."
  #
  # Note: The Rash is automatically optimized every 500 accesses
  #       (Regexps get sorted by how often they get matched).
  #       If this is too low or too high, you can tune it by
  #       setting: `rash.optimize_every = n`
  #
  class Rash
    attr_accessor :optimize_every

    def initialize(initial = {})
      @hash           = {}
      @regexes        = []
      @ranges         = []
      @regex_counts   = Hash.new(0)
      @optimize_every = 500
      @lookups        = 0

      update(initial)
    end

    def update(other)
      other.each do |key, value|
        self[key] = value
      end

      self
    end

    def []=(key, value)
      case key
      when Regexp
        # key = normalize_regex(key)  # this used to just do: /#{regexp}/
        @regexes << key
      when Range
        @ranges << key
      end
      @hash[key] = value
    end

    #
    # Return the first thing that matches the key.
    #
    def [](key)
      all(key).first
    end

    #
    # Return everything that matches the query.
    #
    def all(query)
      return to_enum(:all, query) unless block_given?

      if @hash.include? query
        yield @hash[query]
        return
      end

      case query
      when String
        optimize_if_necessary!

        # see if any of the regexps match the string
        @regexes.each do |regex|
          match = regex.match(query)
          if match
            @regex_counts[regex] += 1
            value = @hash[regex]
            if value.respond_to? :call
              yield value.call(match)
            else
              yield value
            end
          end
        end

      when Integer
        # see if any of the ranges match the integer
        @ranges.each do |range|
          yield @hash[range] if range.include? query
        end

      when Regexp
        # Reverse operation: `rash[/regexp/]` returns all the hash's string keys which match the regexp
        @hash.each do |key, val|
          yield val if key.is_a?(String) && query =~ key
        end
      end
    end

    def method_missing(*args, &block)
      @hash.send(*args, &block)
    end

    private

    def optimize_if_necessary!
      if (@lookups += 1) >= @optimize_every
        @regexes = @regex_counts.sort_by { |regex, count| -count }.map { |regex, count| regex }
        @lookups = 0
      end
    end
  end
end
