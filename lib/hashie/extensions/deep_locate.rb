module Hashie
  module Extensions
    # Extends a Hash with the ability to find key/value pairs within a deeply nested child
    #
    # The searching performed by this module is always a depth-first search. It
    # also traverses collections within nested values of an array, e.g., when a
    # nested key contains an array of hashes, the hashes within the array will
    # also be searched.
    #
    # You can query objects within the collection via the key (in a Hash) and
    # the value (in all Enumerables). You also have access to the object under
    # query at each step through the `object` parameter. Anything that responds
    # to the `call` message with a 3-arity can be used to search the
    # collection.
    #
    # If you are only interested in looking for objects in the collection with
    # a specific key in a Hash, you can pass the key you wish to search for
    # instead of a 3-arity callable.
    #
    # @example Create a new type of Array with this searching capability
    #
    #   class BookList < Array
    #     include Hashie::Extensions::DeepLocate
    #   end
    #
    #   book_list = BookList.new([
    #     { title: "Ruby for beginners", pages: 120 },
    #     { title: "POODR", pages: 272 },
    #     { something: "elses", that_isnt: "a book" }
    #   ])
    #
    #   book_list.deep_locate(:title)
    #   #=> [{:title=>"Ruby for beginners", :pages=>120}, {:title=>"POODR", :pages=>272}]
    #
    #   # This is equivalent to:
    #   book_list.deep_locate(->(key, _value, _object) { key == :title })
    #   #=> [{:title=>"Ruby for beginners", :pages=>120}, {:title=>"POODR", :pages=>272}]
    #
    # @example Find all books with titles in a  pre-existing array by extending the array
    #
    #   books = [
    #     { title: "Ruby for beginners", pages: 120 },
    #     { title: "POODR", pages: 272 },
    #     { something: "elses", that_isnt: "a book" }
    #   ]
    #   books.extend(Hashie::Extensions::DeepLocate)
    #   books.deep_locate(:title)
    #   #=> [{:title=>"Ruby for beginners", :pages=>120}, {:title=>"POODR", :pages=>272}]
    #
    #   # This is equivalent to:
    #   books.deep_locate(->(key, _value, _object) { key == :title })
    #   #=> [{:title=>"Ruby for beginners", :pages=>120}, {:title=>"POODR", :pages=>272}]
    #
    # @example Find all books over 200 pages without extending the object
    #
    #   books = [
    #     { title: "Ruby for beginners", pages: 120 },
    #     { title: "POODR", pages: 272 },
    #     { something: "elses", that_isnt: "a book" }
    #   ]
    #   over_200_pages = -> (key, value, _object) { key == :pages && value > 200 }
    #   Hashie::Extensions::DeepLocate.deep_locate(over_200_pages, books)
    #   #=> [{:title=>"POODR", :pages=>272}]
    module DeepLocate
      # Searches an object for items that match the comparator.
      #
      # @param comparator [#call | #to_s] The comparator to use when querying objects
      #   in the collection. If the comparator is callable, it should be
      #   a 3-arity callable with (key, value, object) as its parameters. If
      #   the comparator is not callable, it will be used to generate
      #   a comparator that looks for the key with the name of the comparator.
      # @param object [Enumerable] The object to search for matching values. Each
      #   item in the enumerable will have the comparator called on it based on
      #   its structure. Hash values will have key arguments, whereas other
      #   enumerable collections will have a `nil` key argument.
      #
      # @note For further examples, see {#deep_locate} or {Hashie::Extensions::DeepLocate}.
      #
      # @example
      #   books = [
      #     { title: "Ruby for beginners", pages: 120 },
      #     { title: "POODR", pages: 272 }
      #   ]
      #
      #   find_hashes_with_title = ->(key, value, object) { key == :title }
      #   Hashie::Extensions::DeepLocate.deep_locate(find_hashes_with_title, books)
      #   # => [{:title=>"Ruby for beginners", :pages=>120}, {:title=>"POODR", :pages=>272}]
      #
      # @api public
      def self.deep_locate(comparator, object)
        comparator = _construct_key_comparator(comparator, object) unless comparator.respond_to?(:call)

        _deep_locate(comparator, object)
      end

      # Searches the collection for items that match a comparator
      #
      # @param comparator [#call | #to_s] The comparator to use when querying objects
      #   in the collection. If the comparator is callable, it should be
      #   a 3-arity callable with (key, value, object) as its parameters. If
      #   the comparator is not callable, it will be used to generate
      #   a comparator that looks for the key with the name of the comparator.
      #
      # @note This is a depth-first search.
      #
      # @example Locate books within a collection
      #   books = [
      #     { title: "Ruby for beginners", pages: 120 },
      #     {
      #       title: "Collection of ruby books",
      #       books: [
      #         { title: "Ruby for the rest of us", pages: 576 }
      #       ]
      #     }
      #   ]
      #
      #   books.extend(Hashie::Extensions::DeepLocate)
      #
      #   books.deep_locate(->(key, value, object) { key == :title && value.include?("Ruby") })
      #   # => [{:title=>"Ruby for beginners", :pages=>120}, {:title=>"Ruby for the rest of us", :pages=>576}]
      #
      #   books.deep_locate(->(key, value, object) { key == :pages && value <= 120 })
      #   # => [{:title=>"Ruby for beginners", :pages=>120}]
      #
      # @api public
      def deep_locate(comparator)
        Hashie::Extensions::DeepLocate.deep_locate(comparator, self)
      end

      private

      # Builds a comparator that matches a key for the object.
      #
      # @param search_key [Symbol, String, #to_s] The key to search for in the
      #   object.
      # @param object [Enumerable] The object that will be searched by the
      #   comparator. If it is a hash with indifferent access, the search key
      #   is modified to look for strings rather than the key itself, due to
      #   how hashes with indifferent access store their keys.
      #
      # @api private
      def self._construct_key_comparator(search_key, object)
        search_key = search_key.to_s if defined?(::ActiveSupport::HashWithIndifferentAccess) && object.is_a?(::ActiveSupport::HashWithIndifferentAccess)
        search_key = search_key.to_s if object.respond_to?(:indifferent_access?) && object.indifferent_access?

        lambda do |non_callable_object|
          ->(key, _, _) { key == non_callable_object }
        end.call(search_key)
      end

      # Searches an object with a comparator and adds matches to the results
      #
      # @param comparator [#call] A 3-arity callable that matches items in a
      #   collection.
      # @param object [Enumerable] The object to search using the comparator.
      # @param result [#push] Any pre-existing results from an earlier call to
      #   this method.
      #
      # @api private
      def self._deep_locate(comparator, object, result = [])
        if object.is_a?(::Enumerable)
          if object.any? { |value| _match_comparator?(value, comparator, object) }
            result.push object
          end
          (object.respond_to?(:values) ? object.values : object.entries).each do |value|
            _deep_locate(comparator, value, result)
          end
        end

        result
      end

      # Maps the comparator to a key/value pair or value only
      #
      # @param value [Object] The value to compare using the comparator.
      # @param comparator [#call] The 3-arity comparator to match against the
      #   value.
      # @param object [Enumerable] The object in which the value exists for
      #   comparison.
      #
      # @api private
      def self._match_comparator?(value, comparator, object)
        if object.is_a?(::Hash)
          key, value = value
        else
          key = nil
        end

        comparator.call(key, value, object)
      end
    end
  end
end
