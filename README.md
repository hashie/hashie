# Hashie [![Build Status](https://secure.travis-ci.org/intridea/hashie.png)](http://travis-ci.org/intridea/hashie) [![Dependency Status](https://gemnasium.com/intridea/hashie.png)](https://gemnasium.com/intridea/hashie) [![Code Climate](https://codeclimate.com/github/intridea/hashie.png)](https://codeclimate.com/github/intridea/hashie) [![Test Coverage](https://codeclimate.com/github/intridea/hashie/badges/coverage.png)](https://codeclimate.com/github/intridea/hashie)

Hashie is a growing collection of tools that extend Hashes and make them more useful.

## Installation

Hashie is available as a RubyGem:

```bash
$ gem install hashie
```

## Upgrading

You're reading the documentation for the next release of Hashie, which should be 3.3.2. Please read [UPGRADING](UPGRADING.md) when upgrading from a previous version. The current stable release is [3.3.1](https://github.com/intridea/hashie/blob/v3.3.1/README.md).

## Hash Extensions

The library is broken up into a number of atomically includeable Hash extension modules as described below. This provides maximum flexibility for users to mix and match functionality while maintaining feature parity with earlier versions of Hashie.

Any of the extensions listed below can be mixed into a class by `include`-ing `Hashie::Extensions::ExtensionName`.

### Coercion

Coercions allow you to set up "coercion rules" based either on the key or the value type to massage data as it's being inserted into the Hash. Key coercions might be used, for example, in lightweight data modeling applications such as an API client:

```ruby
class Tweet < Hash
  include Hashie::Extensions::Coercion
  coerce_key :user, User
end

user_hash = { name: "Bob" }
Tweet.new(user: user_hash)
# => automatically calls User.coerce(user_hash) or
#    User.new(user_hash) if that isn't present.
```

Value coercions, on the other hand, will coerce values based on the type of the value being inserted. This is useful if you are trying to build a Hash-like class that is self-propagating.

```ruby
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
```

### Coercing Collections

```ruby
class Tweet < Hash
  include Hashie::Extensions::Coercion
  coerce_key :mentions, Array[User]
  coerce_key :friends, Set[User]
end

user_hash = { name: "Bob" }
mentions_hash= [user_hash, user_hash]
friends_hash = [user_hash]
tweet = Tweet.new(mentions: mentions_hash, friends: friends_hash)
# => automatically calls User.coerce(user_hash) or
#    User.new(user_hash) if that isn't present on each element of the array

tweet.mentions.map(&:class) # => [User, User]
tweet.friends.class # => Set
```

### Coercing Hashes

```ruby
class Relation
  def initialize(string)
    @relation = string
  end
end

class Tweet < Hash
  include Hashie::Extensions::Coercion
  coerce_key :relations, Hash[User => Relation]
end

user_hash = { name: "Bob" }
relations_hash= { user_hash => "father", user_hash => "friend" }
tweet = Tweet.new(relations: relations_hash)
tweet.relations.map { |k,v| [k.class, v.class] } # => [[User, Relation], [User, Relation]]
tweet.relations.class # => Hash

# => automatically calls User.coerce(user_hash) on each key
#    and Relation.new on each value since Relation doesn't define the `coerce` class method
```

### Coercing Core Types

Hashie handles coercion to the following by using standard conversion methods:

| type     | method   |
|----------|----------|
| Integer  | `#to_i`  |
| Float    | `#to_f`  |
| Complex  | `#to_c`  |
| Rational | `#to_r`  |
| String   | `#to_s`  |
| Symbol   | `#to_sym`|

**Note**: The standard Ruby conversion methods are less strict than you may assume. For example, `:foo.to_i` raises an error but `"foo".to_i` returns 0.

You can also use coerce from the following supertypes with `coerce_value`:
- Integer
- Numeric

Hashie does not have built-in support for coercion boolean values, since Ruby does not have a built-in boolean type or standard method for to a boolean. You can coerce to booleans using a custom proc.

### Coercion Proc

You can use a custom coercion proc on either `#coerce_key` or `#coerce_value`. This is useful for coercing to booleans or other simple types without creating a new class and `coerce` method. For example:

```ruby
class Tweet < Hash
  include Hashie::Extensions::Coercion
  coerce_key :retweeted, ->(v) do
    case v
    when String
      return !!(v =~ /^(true|t|yes|y|1)$/i)
    when Numeric
      return !v.to_i.zero?
    else
      return v == true
    end
  end
end
```

### KeyConversion

The KeyConversion extension gives you the convenience methods of `symbolize_keys` and `stringify_keys` along with their bang counterparts. You can also include just stringify or just symbolize with `Hashie::Extensions::StringifyKeys` or `Hashie::Extensions::SymbolizeKeys`.

### MergeInitializer

The MergeInitializer extension simply makes it possible to initialize a Hash subclass with another Hash, giving you a quick short-hand.

### MethodAccess

The MethodAccess extension allows you to quickly build method-based reading, writing, and querying into your Hash descendant. It can also be included as individual modules, i.e. `Hashie::Extensions::MethodReader`, `Hashie::Extensions::MethodWriter` and `Hashie::Extensions::MethodQuery`.

```ruby
class MyHash < Hash
  include Hashie::Extensions::MethodAccess
end

h = MyHash.new
h.abc = 'def'
h.abc  # => 'def'
h.abc? # => true
```

### MethodAccessWithOverride

The MethodAccessWithOverride extension is like the MethodAccess extension, except that it allows you to override Hash methods. It aliases any overridden method with two leading underscores. To include only this overriding functionality, you can include the single module `Hashie::Extensions::MethodOverridingWriter`.

```ruby
class MyHash < Hash
  include Hashie::Extensions::MethodAccess
end

class MyOverridingHash < Hash
  include Hashie::Extensions::MethodAccessWithOverride
end

non_overriding = MyHash.new
non_overriding.zip = 'a-dee-doo-dah'
non_overriding.zip #=> [[['zip', 'a-dee-doo-dah']]]

overriding = MyHash.new
overriding.zip = 'a-dee-doo-dah'
overriding.zip   #=> 'a-dee-doo-dah'
overriding.__zip #=> [[['zip', 'a-dee-doo-dah']]]
```

### IndifferentAccess

This extension can be mixed in to instantly give you indifferent access to your Hash subclass. This works just like the params hash in Rails and other frameworks where whether you provide symbols or strings to access keys, you will get the same results.

A unique feature of Hashie's IndifferentAccess mixin is that it will inject itself recursively into subhashes *without* reinitializing the hash in question. This means you can safely merge together indifferent and non-indifferent hashes arbitrarily deeply without worrying about whether you'll be able to `hash[:other][:another]` properly.

### IgnoreUndeclared

This extension can be mixed in to silently ignore undeclared properties on initialization instead of raising an error. This is useful when using a Trash to capture a subset of a larger hash.

```ruby
class Person < Trash
  include Hashie::Extensions::IgnoreUndeclared
  property :first_name
  property :last_name
end

user_data = {
  first_name: 'Freddy',
  last_name: 'Nostrils',
  email: 'freddy@example.com'
}

p = Person.new(user_data) # 'email' is silently ignored

p.first_name # => 'Freddy'
p.last_name  # => 'Nostrils'
p.email      # => NoMethodError
```

### DeepMerge

This extension allow you to easily include a recursive merging
system to any Hash descendant:

```ruby
class MyHash < Hash
  include Hashie::Extensions::DeepMerge
end

h1 = MyHash[{ x: { y: [4,5,6] }, z: [7,8,9] }]
h2 = MyHash[{ x: { y: [7,8,9] }, z: "xyz" }]

h1.deep_merge(h2) # => { x: { y: [7, 8, 9] }, z: "xyz" }
h2.deep_merge(h1) # => { x: { y: [4, 5, 6] }, z: [7, 8, 9] }
```

### DeepFetch

This extension can be mixed in to provide for safe and concise retrieval of deeply nested hash values. In the event that the requested key does not exist a block can be provided and its value will be returned.

Though this is a hash extension, it conveniently allows for arrays to be present in the nested structure. This feature makes the extension particularly useful for working with JSON API responses.

```ruby
user = {
  name: { first: 'Bob', last: 'Boberts' },
  groups: [
    { name: 'Rubyists' },
    { name: 'Open source enthusiasts' }
  ]
}

user.extend Hashie::Extensions::DeepFetch

user.deep_fetch :name, :first # => 'Bob'
user.deep_fetch :name, :middle # => 'KeyError: Could not fetch middle'

# using a default block
user.deep_fetch(:name, :middle) { |key| 'default' }  # =>  'default'

# a nested array
user.deep_fetch :groups, 1, :name # => 'Open source enthusiasts'
```

### DeepFind

This extension can be mixed in to provide for concise searching for keys within a deeply nested hash.

It can also search through any Enumerable contained within the hash for objects with the specified key.

Note: The searches are depth-first, so it is not guaranteed that a shallowly nested value will be found before a deeply nested value.

```ruby
user = {
  name: { first: 'Bob', last: 'Boberts' },
  groups: [
    { name: 'Rubyists' },
    { name: 'Open source enthusiasts' }
  ]
}

user.extend Hashie::Extensions::DeepFind

user.deep_find(:name)   #=> { first: 'Bob', last: 'Boberts' }
user.deep_detect(:name) #=> { first: 'Bob', last: 'Boberts' }

user.deep_find_all(:name) #=> [{ first: 'Bob', last: 'Boberts' }, 'Rubyists', 'Open source enthusiasts']
user.deep_select(:name)   #=> [{ first: 'Bob', last: 'Boberts' }, 'Rubyists', 'Open source enthusiasts']
```

## Mash

Mash is an extended Hash that gives simple pseudo-object functionality that can be built from hashes and easily extended. It is intended to give the user easier access to the objects within the Mash through a property-like syntax, while still retaining all Hash functionality.

### Example:

```ruby
mash = Hashie::Mash.new
mash.name? # => false
mash.name # => nil
mash.name = "My Mash"
mash.name # => "My Mash"
mash.name? # => true
mash.inspect # => <Hashie::Mash name="My Mash">

mash = Hashie::Mash.new
# use bang methods for multi-level assignment
mash.author!.name = "Michael Bleigh"
mash.author # => <Hashie::Mash name="Michael Bleigh">

mash = Hashie::Mash.new
# use under-bang methods for multi-level testing
mash.author_.name? # => false
mash.inspect # => <Hashie::Mash>
```

**Note:** The `?` method will return false if a key has been set to false or nil. In order to check if a key has been set at all, use the `mash.key?('some_key')` method instead.

Please note that a Mash will not override methods through the use of the property-like syntax. This can lead to confusion if you expect to be able to access a Mash value through the property-like syntax for a key that conflicts with a method name. However, it protects users of your library from the unexpected behavior of those methods being overridden behind the scenes.

### Example:

```ruby
mash = Hashie::Mash.new
mash.name = "My Mash"
mash.zip = "Method Override?"
mash.zip # => [[["name", "My Mash"]], [["zip", "Method Override?"]]]
```

Mash allows you also to transform any files into a Mash objects.

### Example:

```yml
#/etc/config/settings/twitter.yml
development:
  api_key: 'api_key'
production:
  api_key: <%= ENV['API_KEY'] %> #let's say that ENV['API_KEY'] is set to 'abcd'
```

```ruby
mash = Mash.load('settings/twitter.yml')
mash.development.api_key # => 'localhost'
mash.development.api_key = "foo" # => <# RuntimeError can't modify frozen ...>
mash.development.api_key? # => true
```

You can access a Mash from another class:

```ruby
mash = Mash.load('settings/twitter.yml')[ENV['RACK_ENV']]
Twitter.extend mash.to_module # NOTE: if you want another name than settings, call: to_module('my_settings')
Twitter.settings.api_key # => 'abcd'
```

You can use another parser (by default: YamlErbParser):

```
#/etc/data/user.csv
id | name          | lastname
---|------------- | -------------
1  |John          | Doe
2  |Laurent       | Garnier
```

```ruby
mash = Mash.load('data/user.csv', parser: MyCustomCsvParser)
# => { 1 => { name: 'John', lastname: 'Doe'}, 2 => { name: 'Laurent', lastname: 'Garnier' } }
mash[1] #=> { name: 'John', lastname: 'Doe' }
```

### Mash Extension: SafeAssignment

This extension can be mixed into a Mash to guard the attempted overwriting of methods by property setters. When mixed in, the Mash will raise an `ArgumentError` if you attempt to write a property with the same name as an existing method.

#### Example:

```ruby
class SafeMash < ::Hashie::Mash
  include Hashie::Extensions::Mash::SafeAssignment
end

safe_mash = SafeMash.new
safe_mash.zip   = 'Test' # => ArgumentError
safe_mash[:zip] = 'test' # => still ArgumentError
```

## Dash

Dash is an extended Hash that has a discrete set of defined properties and only those properties may be set on the hash. Additionally, you can set defaults for each property. You can also flag a property as required. Required properties will raise an exception if unset. Another option is message for required properties, which allow you to add custom messages for required property.

### Example:

```ruby
class Person < Hashie::Dash
  property :name, required: true
  property :age, required: true, message: 'must be set.'
  property :email
  property :occupation, default: 'Rubyist'
end

p = Person.new # => ArgumentError: The property 'name' is required for this Dash.
p = Person.new(name: 'Bob') # => ArgumentError: The property 'age' must be set.

p = Person.new(name: "Bob", age: 18)
p.name         # => 'Bob'
p.name = nil   # => ArgumentError: The property 'name' is required for this Dash.
p.age          # => 18
p.age = nil    # => ArgumentError: The property 'age' must be set.
p.email = 'abc@def.com'
p.occupation   # => 'Rubyist'
p.email        # => 'abc@def.com'
p[:awesome]    # => NoMethodError
p[:occupation] # => 'Rubyist'
p.update_attributes!(name: 'Trudy', occupation: 'Evil')
p.occupation   # => 'Evil'
p.name         # => 'Trudy'
p.update_attributes!(occupation: nil)
p.occupation   # => 'Rubyist'
```

Properties defined as symbols are not the same thing as properties defined as strings.

### Example:

```ruby
class Tricky < Hashie::Dash
  property :trick
  property 'trick'
end

p = Tricky.new(trick: 'one', 'trick' => 'two')
p.trick # => 'one', always symbol version
p[:trick] # => 'one'
p['trick'] # => 'two'
```

Note that accessing a property as a method always uses the symbol version.

```ruby
class Tricky < Hashie::Dash
  property 'trick'
end

p = Tricky.new('trick' => 'two')
p.trick # => NoMethodError
```

### Mash and Rails 4 Strong Parameters

To enable compatibility with Rails 4 use the [hashie_rails](http://rubygems.org/gems/hashie_rails) gem.

## Trash

A Trash is a Dash that allows you to translate keys on initialization. It is used like so:

```ruby
class Person < Hashie::Trash
  property :first_name, from: :firstName
end
```

This will automatically translate the <tt>firstName</tt> key to <tt>first_name</tt>
when it is initialized using a hash such as through:

```ruby
Person.new(firstName: 'Bob')
```

Trash also supports translations using lambda, this could be useful when dealing with external API's. You can use it in this way:

```ruby
class Result < Hashie::Trash
  property :id, transform_with: lambda { |v| v.to_i }
  property :created_at, from: :creation_date, with: lambda { |v| Time.parse(v) }
end
```

this will produce the following

```ruby
result = Result.new(id: '123', creation_date: '2012-03-30 17:23:28')
result.id.class         # => Fixnum
result.created_at.class # => Time
```

## Clash

Clash is a Chainable Lazy Hash that allows you to easily construct complex hashes using method notation chaining. This will allow you to use a more action-oriented approach to building options hashes.

Essentially, a Clash is a generalized way to provide much of the same kind of "chainability" that libraries like Arel or Rails 2.x's named_scopes provide.

### Example:

```ruby
c = Hashie::Clash.new
c.where(abc: 'def').order(:created_at)
c # => { where: { abc: 'def' }, order: :created_at }

# You can also use bang notation to chain into sub-hashes,
# jumping back up the chain with _end!
c = Hashie::Clash.new
c.where!.abc('def').ghi(123)._end!.order(:created_at)
c # => { where: { abc: 'def', ghi: 123 }, order: :created_at }

# Multiple hashes are merged automatically
c = Hashie::Clash.new
c.where(abc: 'def').where(hgi: 123)
c # => { where: { abc: 'def', hgi: 123 } }
```

## Rash

Rash is a Hash whose keys can be Regexps or Ranges, which will map many input keys to a value.

A good use case for the Rash is an URL router for a web framework, where URLs need to be mapped to actions; the Rash's keys match URL patterns, while the values call the action which handles the URL.

If the Rash's value is a `proc`, the `proc` will be automatically called with the regexp's MatchData (matched groups) as a block argument.

### Example:

```ruby

# Mapping names to appropriate greetings
greeting = Hashie::Rash.new( /^Mr./ => "Hello sir!", /^Mrs./ => "Evening, madame." )
greeting["Mr. Steve Austin"] # => "Hello sir!"
greeting["Mrs. Steve Austin"] # => "Evening, madame."

# Mapping statements to saucy retorts
mapper = Hashie::Rash.new(
  /I like (.+)/ => proc { |m| "Who DOESN'T like #{m[1]}?!" },
  /Get off my (.+)!/ => proc { |m| "Forget your #{m[1]}, old man!" }
)
mapper["I like traffic lights"] # => "Who DOESN'T like traffic lights?!"
mapper["Get off my lawn!"]      # => "Forget your lawn, old man!"
```

### Auto-optimized

**Note:** The Rash is automatically optimized every 500 accesses (which means that it sorts the list of Regexps, putting the most frequently matched ones at the beginning).

If this value is too low or too high for your needs, you can tune it by setting: `rash.optimize_every = n`.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)

## Copyright

Copyright (c) 2009-2014 Intridea, Inc. (http://intridea.com/) and [contributors](https://github.com/intridea/hashie/graphs/contributors).

MIT License. See [LICENSE](LICENSE) for details.
