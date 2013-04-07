# Hashie [![Build Status](https://secure.travis-ci.org/intridea/hashie.png)](http://travis-ci.org/intridea/hashie) [![Dependency Status](https://gemnasium.com/intridea/hashie.png)](https://gemnasium.com/intridea/hashie)

Hashie is a growing collection of tools that extend Hashes and make
them more useful.

## Installation

Hashie is available as a RubyGem:

    gem install hashie

## Hash Extensions

The library is broken up into a number of atomically includeable Hash
extension modules as described below. This provides maximum flexibility
for users to mix and match functionality while maintaining feature parity
with earlier versions of Hashie.

Any of the extensions listed below can be mixed into a class by
`include`-ing `Hashie::Extensions::ExtensionName`.

### Coercion

Coercions allow you to set up "coercion rules" based either on the key
or the value type to massage data as it's being inserted into the Hash.
Key coercions might be used, for example, in lightweight data modeling
applications such as an API client:

    class Tweet < Hash
      include Hashie::Extensions::Coercion
      coerce_key :user, User
    end

    user_hash = {:name => "Bob"}
    Tweet.new(:user => user_hash)
    # => automatically calls User.coerce(user_hash) or
    #    User.new(user_hash) if that isn't present.

Value coercions, on the other hand, will coerce values based on the type
of the value being inserted. This is useful if you are trying to build a
Hash-like class that is self-propagating.

    class SpecialHash < Hash
      include Hashie::Extensions::Coercion
      coerce_value Hash, SpecialHash

      def initialize(hash = {})
        super
        hash.each_pair do |k,v|
          self[k] = v
        end
      end
    end

### KeyConversion

The KeyConversion extension gives you the convenience methods of
`symbolize_keys` and `stringify_keys` along with their bang
counterparts. You can also include just stringify or just symbolize with
`Hashie::Extensions::StringifyKeys` or `Hashie::Extensions::SymbolizeKeys`.

### MergeInitializer

The MergeInitializer extension simply makes it possible to initialize a
Hash subclass with another Hash, giving you a quick short-hand.

### MethodAccess

The MethodAccess extension allows you to quickly build method-based
reading, writing, and querying into your Hash descendant. It can also be
included as individual modules, i.e. `Hashie::Extensions::MethodReader`,
`Hashie::Extensions::MethodWriter` and `Hashie::Extensions::MethodQuery`

    class MyHash < Hash
      include Hashie::Extensions::MethodAccess
    end

    h = MyHash.new
    h.abc = 'def'
    h.abc  # => 'def'
    h.abc? # => true

### IndifferentAccess

This extension can be mixed in to instantly give you indifferent access
to your Hash subclass. This works just like the params hash in Rails and
other frameworks where whether you provide symbols or strings to access
keys, you will get the same results.

A unique feature of Hashie's IndifferentAccess mixin is that it will
inject itself recursively into subhashes *without* reinitializing the
hash in question. This means you can safely merge together indifferent
and non-indifferent hashes arbitrarily deeply without worrying about
whether you'll be able to `hash[:other][:another]` properly.

### DeepMerge

This extension allow you to easily include a recursive merging
system to any Hash descendant:

    class MyHash < Hash
      include Hashie::Extensions::DeepMerge
    end

    h1 = MyHash.new
    h2 = MyHash.new

    h1 = {:x => {:y => [4,5,6]}, :z => [7,8,9]}
    h2 = {:x => {:y => [7,8,9]}, :z => "xyz"}

    h1.deep_merge(h2) #=> { :x => {:y => [7, 8, 9]}, :z => "xyz" }
    h2.deep_merge(h1) #=> { :x => {:y => [4, 5, 6]}, :z => [7, 8, 9] }

## Mash

Mash is an extended Hash that gives simple pseudo-object functionality
that can be built from hashes and easily extended. It is designed to
be used in RESTful API libraries to provide easy object-like access
to JSON and XML parsed hashes.

### Example:

    mash = Hashie::Mash.new
    mash.name? # => false
    mash.name # => nil
    mash.name = "My Mash"
    mash.name # => "My Mash"
    mash.name? # => true
    mash.inspect # => <Hashie::Mash name="My Mash">

    mash = Mash.new
    # use bang methods for multi-level assignment
    mash.author!.name = "Michael Bleigh"
    mash.author # => <Hashie::Mash name="Michael Bleigh">

    mash = Mash.new
    # use under-bang methods for multi-level testing
    mash.author_.name? # => false
    mash.inspect # => <Hashie::Mash>

**Note:** The `?` method will return false if a key has been set
to false or nil. In order to check if a key has been set at all, use the
`mash.key?('some_key')` method instead.

## Dash

Dash is an extended Hash that has a discrete set of defined properties
and only those properties may be set on the hash. Additionally, you
can set defaults for each property. You can also flag a property as
required. Required properties will raise an exception if unset.

### Example:

    class Person < Hashie::Dash
      property :name, :required => true
      property :email
      property :occupation, :default => 'Rubyist'
    end

    p = Person.new # => ArgumentError: The property 'name' is required for this Dash.

    p = Person.new(:name => "Bob")
    p.name # => 'Bob'
    p.name = nil # => ArgumentError: The property 'name' is required for this Dash.
    p.email = 'abc@def.com'
    p.occupation   # => 'Rubyist'
    p.email        # => 'abc@def.com'
    p[:awesome]    # => NoMethodError
    p[:occupation] # => 'Rubyist'

## Trash

A Trash is a Dash that allows you to translate keys on initialization.
It is used like so:

    class Person < Hashie::Trash
      property :first_name, :from => :firstName
    end

This will automatically translate the <tt>firstName</tt> key to <tt>first_name</tt>
when it is initialized using a hash such as through:

    Person.new(:firstName => 'Bob')

Trash also supports translations using lambda, this could be useful when dealing with
external API's. You can use it in this way:

    class Result < Hashie::Trash
      property :id, :transform_with => lambda { |v| v.to_i }
      property :created_at, :from => :creation_date, :with => lambda { |v| Time.parse(v) }
    end

this will produce the following

    result = Result.new(:id => '123', :creation_date => '2012-03-30 17:23:28')
    result.id.class         # => Fixnum
    result.created_at.class # => Time

## Clash

Clash is a Chainable Lazy Hash that allows you to easily construct
complex hashes using method notation chaining. This will allow you
to use a more action-oriented approach to building options hashes.

Essentially, a Clash is a generalized way to provide much of the same
kind of "chainability" that libraries like Arel or Rails 2.x's named_scopes
provide.

### Example

    c = Hashie::Clash.new
    c.where(:abc => 'def').order(:created_at)
    c # => {:where => {:abc => 'def'}, :order => :created_at}

    # You can also use bang notation to chain into sub-hashes,
    # jumping back up the chain with _end!
    c = Hashie::Clash.new
    c.where!.abc('def').ghi(123)._end!.order(:created_at)
    c # => {:where => {:abc => 'def', :ghi => 123}, :order => :created_at}

    # Multiple hashes are merged automatically
    c = Hashie::Clash.new
    c.where(:abc => 'def').where(:hgi => 123)
    c # => {:where => {:abc => 'def', :hgi => 123}}

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)

## Authors

* Michael Bleigh

## Copyright

Copyright (c) 2009-2013 Intridea, Inc. (http://intridea.com/). See LICENSE for details.
