# Hashie

[![Join the chat at https://gitter.im/hashie/hashie](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/hashie/hashie?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Gem Version](http://img.shields.io/gem/v/hashie.svg)](http://badge.fury.io/rb/hashie)
[![Build Status](https://github.com/hashie/hashie/actions/workflows/test.yml/badge.svg)](https://github.com/hashie/hashie/actions/workflows/test.yml)
[![Coverage Status](https://coveralls.io/repos/github/hashie/hashie/badge.svg)](https://coveralls.io/github/hashie/hashie)

[![eierlegende Wollmilchsau](./mascot.svg)](#mascot) Hashie is a growing collection of tools that extend Hashes and make them more useful.

# Table of Contents

- [Installation](#installation)
- [Stable Release](#stable-release)
- [Hash Extensions](#hash-extensions)
- [Logging](#logging)
  - [Coercion](#coercion)
  - [Coercing Collections](#coercing-collections)
  - [Coercing Hashes](#coercing-hashes)
  - [Coercing Core Types](#coercing-core-types)
  - [Coercion Proc](#coercion-proc)
    - [A note on circular coercion](#a-note-on-circular-coercion)
  - [Nil Values and Defaults](#nil-values-and-defaults)
  - [KernelCoercion](#kernelcoercion)
  - [Callable Coercion](#callable-coercion)
  - [Coercion with dry-types](#coercion-with-dry-types)
  - [Coercion with ActiveModel](#coercion-with-activemodel)
  - [KeyConversion](#keyconversion)
  - [MergeInitializer](#mergeinitializer)
  - [DeepMergeInitializer](#deepmergeinitializer)
  - [MethodAccess](#methodaccess)
  - [BlockAccess](#blockaccess)
  - [Persistable](#persistable)
  - [MethodAccessWithOverride](#methodaccesswithoverride)
  - [MethodOverridingInitializer](#methodoverridinginitializer)
  - [IndifferentAccess](#indifferentaccess)
  - [IgnoreUndeclared](#ignoreundeclared)
  - [DeepMerge](#deepmerge)
  - [DeepFetch](#deepfetch)
  - [DeepFind](#deepfind)
  - [DeepGrep](#deepgrep)
  - [DeepLocate](#deeplocate)
- [StrictKeyAccess](#strictkeyaccess)
- [Mash](#mash)
  - [KeepOriginalKeys](#keeporiginalkeys)
  - [PermissiveRespondTo](#permissiverespondto)
  - [SafeAssignment](#safeassignment)
  - [TransformKeys](#transformkeys)
  - [UnderscoreKeys](#underscorekeys)
  - [SymbolizeKeys](#symbolizekeys)
  - [DefineAccessors](#defineaccessors)
  - [StrictKeyAccess](#strictkeyaccess-1)
  - [RequiredKeys](#requiredkeys)
- [Dash](#dash)
  - [Validations with ActiveModel](#validations-with-activemodel)
  - [Potential Gotchas](#potential-gotchas)
  - [PropertyTranslation](#propertytranslation)
  - [Mash and Rails 4 Strong Parameters](#mash-and-rails-4-strong-parameters)
  - [Coercion](#coercion-1)
  - [PredefinedValues](#predefinedvalues)
- [Trash](#trash)
- [Clash](#clash)
- [Rash](#rash)
  - [Auto-Optimized](#auto-optimized)
- [Mascot](#mascot)
- [Contributing](#contributing)
- [Copyright](#copyright)

## Installation

Hashie requires Ruby 3.0 or newer.

Hashie is available as a RubyGem:

```bash
$ gem install hashie
```

## Stable Release

You're reading the documentation for the next release of Hashie, which should be 5.1.1.
The current stable release is [5.1.0](https://github.com/hashie/hashie/blob/v5.1.0/README.md).

## Hash Extensions

The library is broken up into a number of atomically includable Hash extension modules as described below. This provides maximum flexibility for users to mix and match functionality while maintaining feature parity with earlier versions of Hashie.

Any of the extensions listed below can be mixed into a class by `include`-ing `Hashie::Extensions::ExtensionName`.

## Logging

Hashie has a built-in logger that you can override. By default, it logs to `STDOUT` but can be replaced by any `Logger` class. The logger is accessible on the Hashie module, as shown below:

```ruby
# Set the logger to the Rails logger
Hashie.logger = Rails.logger
```

### Coercion

Coercions allow you to set up "coercion rules" based either on the key or the value type to massage data as it's being inserted into the Hash. Key coercions might be used, for example, in lightweight data modeling applications such as an API client:

```ruby
class Tweet < Hash
  include Hashie::Extensions::Coercion
  include Hashie::Extensions::MergeInitializer
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

Hashie does not choose a built-in boolean coercion policy. You can coerce to booleans using a custom proc or an external callable coercer.

### Coercion Proc

You can use a custom coercion proc on either `#coerce_key` or `#coerce_value`. This is useful for coercing to booleans or other simple types without creating a new class and `coerce` method. For example:

```ruby
class Tweet < Hash
  include Hashie::Extensions::Coercion
  coerce_key :retweeted, ->(v) do
    case v
    when String
      !!(v =~ /\A(true|t|yes|y|1)\z/i)
    when Numeric
      !v.to_i.zero?
    else
      v == true
    end
  end
end
```

#### A note on circular coercion

Since `coerce_key` is a class-level method, you cannot have circular coercion without the use of a proc. For example:

```ruby
class CategoryHash < Hash
  include Hashie::Extensions::Coercion
  include Hashie::Extensions::MergeInitializer

  coerce_key :products, Array[ProductHash]
end

class ProductHash < Hash
  include Hashie::Extensions::Coercion
  include Hashie::Extensions::MergeInitializer

  coerce_key :categories, Array[CategoriesHash]
end
```

This will fail with a `NameError` for `CategoryHash::ProductHash` because `ProductHash` is not defined at the point that `coerce_key` is happening for `CategoryHash`.

To work around this, you can use a coercion proc. For example, you could do:

```ruby
class CategoryHash < Hash
  # ...
  coerce_key :products, ->(value) do
    return value.map { |v| ProductHash.new(v) } if value.respond_to?(:map)

    ProductHash.new(value)
  end
end
```

### Nil Values and Defaults

Top-level `nil` values bypass coercion: `coerce_key :description, String` does not turn `nil` into `''`. A coercion rule converts supplied non-nil values; it does not define a default. Use a Dash property default when missing or nil input should become an empty string:

```ruby
class DescriptionParams < Hashie::Dash
  include Hashie::Extensions::Coercion

  property :description, default: ''
  coerce_key :description, String
end

params = DescriptionParams.new(description: nil)
params.description # => ''
DescriptionParams.new.description # => ''
DescriptionParams.new(description: 123).description # => '123'

params.description = nil
params.description # => nil
params.update_attributes!(description: nil)
params.description # => ''
```

Dash initialization and `update_attributes!` apply property defaults to nil values. Direct assignments through a property writer or `[]=` retain nil and do not reapply defaults. These rules also apply to subclasses. Dash already initializes attributes; it does not need `MergeInitializer`.

### KernelCoercion

By default, `Hashie::Extensions::Coercion` coerces core types using lenient methods like `#to_i` and `#to_f`, which can silently produce undesirable results:

```ruby
'abcd'.to_f # => 0.0
```

The `Hashie::Extensions::KernelCoercion` mixin extends `Coercion` to use the stricter `Kernel` methods (e.g. `Kernel#Integer`, `Kernel#Float`) instead, which raise an error for invalid input rather than silently coercing it:

```ruby
class StrictHash < Hash
  include Hashie::Extensions::Coercion
  extend Hashie::Extensions::KernelCoercion

  coerce_key :count, Integer
end

hash = StrictHash.new
hash[:count] = '5'    # => 5
hash[:count] = 'abcd' # => Hashie::CoercionError: Cannot coerce property :count from String to Integer: invalid value for Integer(): "abcd"
```

This applies to `Integer`, `Float`, `Complex`, `Rational` and `String`. There is no strict `Kernel` method equivalent for `Symbol`, so `Symbol` coercion always uses the default, lenient `#to_sym` behavior.

### Callable Coercion

Coercion also accepts bound methods and other objects responding to `call`. Existing collection and class/module dispatch takes precedence over `call` for non-Proc targets; other callable objects use `call` even if they also expose `coerce` or `new`. Callable coercers work with `coerce_key`, `coerce_value`, collection members, and Dash's `coerce:` property option.

Hashie does not load or depend on external type libraries. The callable determines conversion and validation; no additional output validation or empty-string normalization is applied. Hashie preserves its existing `nil` bypass for top-level assignments, even when the callable would reject `nil`; nested collection members are passed to their coercers. As with existing coercers, `TypeError`, `ArgumentError`, and `NoMethodError` during assignment become `Hashie::CoercionError`; other exceptions propagate unchanged.

### Coercion with dry-types

Add `dry-types` to your application's Gemfile:

```ruby
gem 'dry-types'
```

Pass a [dry-types](https://dry-rb.org/gems/dry-types/main/) object directly as the coercer:

```ruby
require 'dry-types'
require 'hashie'

class Settings < Hashie::Dash
  include Hashie::Extensions::Dash::Coercion

  property :enabled, coerce: Dry::Types['params.bool']
end

Settings.new(enabled: 'false').enabled # => false
Settings.new(enabled: nil).enabled # => nil (Hashie bypasses coercion)
Settings.new(enabled: 'unknown') # raises Dry::Types::CoercionError
```

The `params.bool` type converts recognized boolean representations and rejects unknown values and empty strings. Use `Dry::Types['strict.bool']` for validation without conversion: it accepts `true` and `false`, but rejects strings such as `'false'`. Top-level `nil` assignments still bypass coercion.

The bypass applies only to top-level assignments, not collection members:

```ruby
class Flags < Hashie::Dash
  include Hashie::Extensions::Dash::Coercion

  property :values, coerce: Array[Dry::Types['strict.bool']]
end

Flags.new(values: nil).values # => nil
Flags.new(values: [true, nil]) # raises Dry::Types::ConstraintError
```

### Coercion with ActiveModel

Add `activemodel` to your application's Gemfile if it is not already provided by Rails:

```ruby
gem 'activemodel'
```

Pass a bound [ActiveModel type](https://api.rubyonrails.org/classes/ActiveModel/Type/Boolean.html) `cast` method as the coercer:

```ruby
require 'active_model'
require 'hashie'

class Settings < Hashie::Dash
  include Hashie::Extensions::Dash::Coercion

  property :enabled, coerce: ActiveModel::Type::Boolean.new.method(:cast)
end

Settings.new(enabled: 'off').enabled # => false
Settings.new(enabled: nil).enabled # => nil (Hashie bypasses coercion)
Settings.new(enabled: '').enabled # => nil
Settings.new(enabled: 'unknown').enabled # => true
```

ActiveModel's boolean policy differs from dry-types: it treats an empty string as `nil`, recognized false values as false, and most other values as true. Choose the library whose conversion policy matches your application.

### KeyConversion

The KeyConversion extension gives you the convenience methods of `symbolize_keys` and `stringify_keys` along with their bang counterparts. You can also include just stringify or just symbolize with `Hashie::Extensions::StringifyKeys` or `Hashie::Extensions::SymbolizeKeys`.

Hashie also has a utility method for converting keys on a Hash without a mixin:

```ruby
Hashie.symbolize_keys! hash # => Symbolizes all string keys of hash.
Hashie.symbolize_keys hash # => Returns a copy of hash with string keys symbolized.
Hashie.stringify_keys! hash # => Stringifies keys of hash.
Hashie.stringify_keys hash # => Returns a copy of hash with keys stringified.
```

### MergeInitializer

The MergeInitializer extension simply makes it possible to initialize a Hash subclass with another Hash, giving you a quick short-hand.

### DeepMergeInitializer

The `DeepMergeInitializer` extension initializes a `Hash` subclass from another hash, like `MergeInitializer`, but also converts nested hashes to the same concrete class. This includes hashes inside arrays, even when arrays are nested.

```ruby
class MyHash < Hash
  include Hashie::Extensions::DeepMergeInitializer
  include Hashie::Extensions::IndifferentAccess
  include Hashie::Extensions::MethodAccess
end

hash = MyHash.new(foo: { bar: 1 }, children: [{ name: 'Bob' }])
hash.foo.bar # => 1
hash['foo']['bar'] # => 1
hash.children.first.name # => 'Bob'
hash.foo.class # => MyHash
```

Use this extension instead of `MergeInitializer` on plain `Hash` subclasses; Mash already provides recursive conversion, and Dash/Trash have their own property-aware initializers. The subclass must accept the same initializer arguments. Conversion happens only during initialization, not on later assignment or merge, and does not change `MethodAccess` itself.

An optional second argument supplies a default value, including `false`; alternatively, a block supplies a default proc. The same default is passed to every converted hash. As with `Hash`, a non-nil default value cannot be combined with a block.

```ruby
hash = MyHash.new({ foo: {} }, false)
hash[:missing] # => false
hash.foo[:missing] # => false
```

Input hashes and arrays are rebuilt without modifying the source; keys and non-container values are retained. Use acyclic input data.

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

### BlockAccess

`Hashie::Extensions::BlockAccess` adds block-style construction of nested hashes.
It works with Hash subclasses, including Mash and Dash, without changing reads
or writes made without a block. For a plain Hash subclass, include `MethodAccess`
first if you also want method-style readers and writers.

```ruby
class Configuration < Hash
  include Hashie::Extensions::MethodAccess
  include Hashie::Extensions::BlockAccess
end

config = Configuration.new
config.author do |author|
  author.name = 'Michael Bleigh'
end
config.author.name #=> 'Michael Bleigh'

config.test(:one) { |one| one.foo = 'bar' }
config.test(:two) { |two| two.hurp = 'derp' }
config.test.one.foo  #=> 'bar'
config.test.two.hurp #=> 'derp'
```

Include only `BlockAccess` in a Mash subclass; Mash already supplies method access.
Bracket calls also accept a block: `config['author'] { |author| author.name = 'Bob' }`.
Each call returns the child, not the block's result. Existing hashes are reused
without conversion, while missing children are constructed using the containing
hash's class and stored before they are yielded. Constructors must accept no
arguments. Existing non-hash values, including `nil` and `false`, raise `TypeError`
rather than being overwritten.

Dash properties must be declared, and its constructor and property validations
still apply. Real methods (such as `each`) and Mash's `?`, `!`, `=`, and `_`
suffixes keep their existing behavior.

### Persistable

`Hashie::Extensions::Persistable` adds opt-in YAML file persistence to classes whose constructors accept a hash. Plain Hash subclasses can include `MergeInitializer` first.

```ruby
class Configuration < Hashie::Mash
  include Hashie::Extensions::Persistable
end

config = Configuration.new(name: 'example')
config.save('config.yaml')
loaded = Configuration.load('config.yaml')
loaded.name = 'updated'
loaded.save # writes back to config.yaml
```

`save` returns and remembers the absolute path only after a successful write. It atomically replaces the destination using a temporary file in the same directory, preserves existing file permissions, and creates new files with private permissions. A failed write leaves the remembered path unchanged.

Files contain plain YAML data, not Ruby class tags or persistence metadata. Loading uses `Psych.safe_load`, permits symbols for declared Dash/Trash properties, rejects aliases and non-hash roots, and never evaluates ERB. String and symbol keys retain their types; Dash/Trash files must use keys accepted by their constructors. Nested Hashie classes are not encoded: constructors such as Mash may reconstruct their own nested types, while Dash retains nested plain hashes. Supported values are hashes, arrays, strings, symbols, numbers, booleans, and `nil`; cycles and unsupported objects are rejected.

Including this extension explicitly replaces an inherited class-level `load` on that subclass. Ordinary `Hashie::Mash.load` retains its existing caching and YAML/ERB behavior. No autosave or other serialization formats are provided.

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

overriding = MyOverridingHash.new
overriding.zip = 'a-dee-doo-dah'
overriding.zip   #=> 'a-dee-doo-dah'
overriding.__zip #=> [[['zip', 'a-dee-doo-dah']]]
```

### MethodOverridingInitializer

The MethodOverridingInitializer extension will override hash methods if you pass in a normal hash to the constructor. It aliases any overridden method with two leading underscores. To include only this initializing functionality, you can include the single module `Hashie::Extensions::MethodOverridingInitializer`.

```ruby
class MyHash < Hash
end

class MyOverridingHash < Hash
  include Hashie::Extensions::MethodOverridingInitializer
end

non_overriding = MyHash.new(zip: 'a-dee-doo-dah')
non_overriding.zip #=> []

overriding = MyOverridingHash.new(zip: 'a-dee-doo-dah')
overriding.zip   #=> 'a-dee-doo-dah'
overriding.__zip #=> [[['zip', 'a-dee-doo-dah']]]
```

### IndifferentAccess

This extension can be mixed in to your Hash subclass to allow you to use Strings or Symbols interchangeably as keys; similar to the `params` hash in Rails.

In addition, IndifferentAccess will also inject itself into sub-hashes so they behave the same.

```ruby
class MyHash < Hash
  include Hashie::Extensions::MergeInitializer
  include Hashie::Extensions::IndifferentAccess
end

myhash = MyHash.new(:cat => 'meow', 'dog' => 'woof')
myhash['cat'] # => "meow"
myhash[:cat]  # => "meow"
myhash[:dog]  # => "woof"
myhash['dog'] # => "woof"

# Auto-Injecting into sub-hashes.
myhash['fishes'] = {}
myhash['fishes'].class # => Hash
myhash['fishes'][:food] = 'flakes'
myhash['fishes']['food'] # => "flakes"
```

To get back a normal, not-indifferent Hash, you can use `#to_hash` on the indifferent hash. It exports the keys as strings, not symbols:

```ruby
myhash = MyHash.new
myhash["foo"] = "bar"
myhash[:foo]  #=> "bar"

normal_hash = myhash.to_hash
myhash["foo"]  #=> "bar"
myhash[:foo]  #=> nil
```

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

This extension allows you to easily include a recursive merging
system into any Hash descendant:

```ruby
class MyHash < Hash
  include Hashie::Extensions::DeepMerge
end

h1 = MyHash[{ x: { y: [4,5,6] }, z: [7,8,9] }]
h2 = MyHash[{ x: { y: [7,8,9] }, z: "xyz" }]

h1.deep_merge(h2) # => { x: { y: [7, 8, 9] }, z: "xyz" }
h2.deep_merge(h1) # => { x: { y: [4, 5, 6] }, z: [7, 8, 9] }
```

Like with Hash#merge in the standard library, a block can be provided to merge values:

```ruby
class MyHash < Hash
  include Hashie::Extensions::DeepMerge
end

h1 = MyHash[{ a: 100, b: 200, c: { c1: 100 } }]
h2 = MyHash[{ b: 250, c: { c1: 200 } }]

h1.deep_merge(h2) { |key, this_val, other_val| this_val + other_val }
# => { a: 100, b: 450, c: { c1: 300 } }
```


New nested hashes use plain `Hash` destinations by default. To preserve incoming hash subclasses, override the protected `deep_merge_new_hash(source)` hook:

```ruby
class PreservingHash < Hash
  include Hashie::Extensions::DeepMerge

  protected

  def deep_merge_new_hash(source)
    # Use source.class.new if no constructor arguments or instance-specific state are needed.
    source.dup.clear
  end
end
```

The hook must return an empty, writable hash. Duplicating and clearing the source preserves its class, instance state, and hash defaults without requiring a zero-argument constructor. It runs for each incoming nested hash that cannot merge into an existing destination hash, including at deeper levels. Existing destination hashes retain their own types. Both `deep_merge` and `deep_merge!` use the hook; neither clears the source. Hashes inside arrays follow the existing array replacement behavior and are not processed by this hook. Custom subclasses with special duplication, clearing, or assignment behavior may need their own factory implementation.

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

### DeepGrep

Search nested hashes and arrays for string or symbol keys and values matching a regular expression. Include `Hashie::Extensions::DeepGrep` to call `deep_grep(pattern)`.

```ruby
class Library < Hash
  include Hashie::Extensions::DeepGrep
end

books = Library[
  'Uncategorized' => [
    { title: 'Ruby for beginners', pages: 120 },
    { title: 'CSS for intermediates', pages: 80 }
  ],
  'Collection of Ruby books' => [{ title: 'That other language by Matz', pages: 578 }]
]

books.deep_grep(/ruby/i)
# => [
#      { title: 'Ruby for beginners', pages: 120 },
#      { 'Collection of Ruby books' => [{ title: 'That other language by Matz', pages: 578 }] }
#    ]

books.deep_grep(/missing/) # => []
```

For plain hashes or arrays, call `Hashie::Extensions::DeepGrep.deep_grep(pattern, object)` directly.

A matching hash key returns a new one-entry hash containing that key and its original subtree; that subtree is not searched further. A matching scalar hash value returns its containing hash once, preserving sibling context. A matching scalar array element returns just that element, not the whole array. Non-text scalars and container keys are not searched. Results follow depth-first insertion order; shared containers can appear at multiple input locations, and cycles are skipped. Input data is not modified, but returned containers share references with the input.

### DeepLocate

This extension can be mixed in to provide a depth first search based search for enumerables matching a given comparator callable.

It returns all enumerables which contain at least one element, for which the given comparator returns ```true```.

Because the container objects are returned, the result elements can be modified in place. This way, one can perform modifications on deeply nested hashes without the need to know the exact paths.

```ruby

books = [
  {
    title: "Ruby for beginners",
    pages: 120
  },
  {
    title: "CSS for intermediates",
    pages: 80
  },
  {
    title: "Collection of ruby books",
    books: [
      {
        title: "Ruby for the rest of us",
        pages: 576
      }
    ]
  }
]

books.extend(Hashie::Extensions::DeepLocate)

# for ruby 1.9 leave *no* space between the lambda rocket and the braces
# http://ruby-journal.com/becareful-with-space-in-lambda-hash-rocket-syntax-between-ruby-1-dot-9-and-2-dot-0/

books.deep_locate -> (key, value, object) { key == :title && value.include?("Ruby") }
# => [{:title=>"Ruby for beginners", :pages=>120}, {:title=>"Ruby for the rest of us", :pages=>576}]

books.deep_locate -> (key, value, object) { key == :pages && value <= 120 }
# => [{:title=>"Ruby for beginners", :pages=>120}, {:title=>"CSS for intermediates", :pages=>80}]
```

## StrictKeyAccess

This extension can be mixed in to allow a Hash to raise an error when attempting to extract a value using a non-existent key.

```ruby
class StrictKeyAccessHash < Hash
  include Hashie::Extensions::StrictKeyAccess
end

>> hash = StrictKeyAccessHash[foo: "bar"]
=> {:foo=>"bar"}
>> hash[:foo]
=> "bar"
>> hash[:cow]
  KeyError: key not found: :cow
```

## Mash

Mash is an extended Hash that gives simple pseudo-object functionality that can be built from hashes and easily extended. It is intended to give the user easier access to the objects within the Mash through a property-like syntax, while still retaining all Hash functionality.

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

_How does Mash handle conflicts with pre-existing methods?_

Please note that a Mash will not override methods through the use of the property-like syntax. This can lead to confusion if you expect to be able to access a Mash value through the property-like syntax for a key that conflicts with a method name. However, it protects users of your library from the unexpected behavior of those methods being overridden behind the scenes.

```ruby
mash = Hashie::Mash.new
mash.name = "My Mash"
mash.zip = "Method Override?"
mash.zip # => [[["name", "My Mash"]], [["zip", "Method Override?"]]]
```

Since Mash gives you the ability to set arbitrary keys that then act as methods, Hashie logs when there is a conflict between a key and a pre-existing method. You can set the logger that this logs message to via the global Hashie logger:

```ruby
Hashie.logger = Rails.logger
```

You can also disable the logging in subclasses of Mash:

```ruby
class Response < Hashie::Mash
  disable_warnings
end
```

The default is to disable logging for all methods that conflict. If you would like to only disable the logging for specific methods, you can include an array of method keys:

```ruby
class Response < Hashie::Mash
  disable_warnings :zip, :zap
end
```

This behavior is cumulative. The examples above and below behave identically.

```ruby
class Response < Hashie::Mash
  disable_warnings :zip
  disable_warnings :zap
end
```

Disable warnings will honor the last `disable_warnings` call. Calling without parameters will override the ignored methods list, and calling with parameters will create a new ignored methods list. This includes child classes that inherit from a class that disables warnings.

```ruby
class Message < Hashie::Mash
  disable_warnings :zip, :zap
  disable_warnings
end

# No errors will be logged
Message.new(merge: 'true', compact: true)
```

```ruby
class Message < Hashie::Mash
  disable_warnings
end

class Response < Message
  disable_warnings :zip, :zap
end

# 2 errors will be logged
Response.new(merge: 'true', compact: true, zip: '90210', zap: 'electric')
```

If you would like to create an anonymous subclass of a Hashie::Mash with key conflict warnings disabled:

```ruby
Hashie::Mash.quiet.new(zip: '90210', compact: true) # no errors logged
Hashie::Mash.quiet(:zip).new(zip: '90210', compact: true) # error logged for compact
```

_How does the wrapping of Mash sub-Hashes work?_

Mash duplicates any sub-Hashes that you add to it and wraps them in a Mash. This allows for infinite chaining of nested Hashes within a Mash without modifying the object(s) that are passed into the Mash. When you subclass Mash, the subclass wraps any sub-Hashes in its own class. This preserves any extensions that you mixed into the Mash subclass and allows them to work within the sub-Hashes, in addition to the main containing Mash.

```ruby
mash = Hashie::Mash.new(name: "Hashie", dependencies: { rake: "< 11", rspec: "~> 3.0" })
mash.dependencies.class #=> Hashie::Mash

class MyGem < Hashie::Mash; end
my_gem = MyGem.new(name: "Hashie", dependencies: { rake: "< 11", rspec: "~> 3.0" })
my_gem.dependencies.class #=> MyGem
```

_How does Mash handle key types which cannot be symbolized?_

Mash preserves keys which cannot be converted *directly* to both a string and a symbol, such as numeric keys. Since Mash is conceived to provide pseudo-object functionality, handling keys which cannot represent a method call falls outside its scope of value.

```ruby
Hashie::Mash.new('1' => 'one string', :'1' => 'one sym', 1 => 'one num')
# => {"1"=>"one sym", 1=>"one num"}
```

The symbol key `:'1'` is converted the string `'1'` to support indifferent access and consequently its value `'one sym'` will override the previously set `'one string'`. However, the subsequent key of `1` cannot directly convert to a symbol and therefore **not** converted to the string `'1'` that would otherwise override the previously set value of `'one sym'`.

_What else can Mash do?_

Mash allows you also to transform any files into a Mash objects.

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

You can also load with a `Pathname` object:

```ruby
mash = Mash.load(Pathname 'settings/twitter.yml')
mash.development.api_key # => 'localhost'
```

By default, `Mash.load` evaluates ERB before parsing YAML. Only use it with trusted files; `YAML.safe_load` does not make ERB evaluation safe. To parse untrusted or plain YAML without evaluating ERB, explicitly select `YamlParser`:

```ruby
mash = Mash.load('data.yml', parser: Hashie::Extensions::Parsers::YamlParser)
```

You can access a Mash from another class:

```ruby
mash = Mash.load('settings/twitter.yml')[ENV['RACK_ENV']]
Twitter.extend mash.to_module # NOTE: if you want another name than settings, call: to_module('my_settings')
Twitter.settings.api_key # => 'abcd'
```

You can use another parser (by default: [YamlErbParser](lib/hashie/extensions/parsers/yaml_erb_parser.rb), which evaluates ERB):

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

Both built-in YAML parsers use `YAML.safe_load`.

Specify `permitted_symbols`, `permitted_classes` and `aliases` options as needed.

```ruby
Mash.load('data/user.csv', permitted_classes: [Symbol], permitted_symbols: [], aliases: false)
```

### KeepOriginalKeys

This extension can be mixed into a Mash to keep the form of any keys passed directly into the Mash. By default, Mash converts symbol keys to strings to give indifferent access. This extension still allows indifferent access, but keeps the form of the keys to eliminate confusion when you're not expecting the keys to change.

```ruby
class KeepingMash < ::Hashie::Mash
  include Hashie::Extensions::Mash::KeepOriginalKeys
end

mash = KeepingMash.new(:symbol_key => :symbol, 'string_key' => 'string')
mash.to_hash == { :symbol_key => :symbol, 'string_key' => 'string' }  #=> true
mash.symbol_key  #=> :symbol
mash[:symbol_key]  #=> :symbol
mash['symbol_key']  #=> :symbol
mash.string_key  #=> 'string'
mash['string_key']  #=> 'string'
mash[:string_key]  #=> 'string'
```

### PermissiveRespondTo

By default, Mash only states that it responds to built-in methods, affixed methods (e.g. setters, underbangs, etc.), and keys that it currently contains. That means it won't state that it responds to a getter for an unset key, as in the following example:

```ruby
mash = Hashie::Mash.new(a: 1)
mash.respond_to? :b  #=> false
```

This means that by default Mash is not a perfect match for use with a SimpleDelegator since the delegator will not forward messages for unset keys to the Mash even though it can handle them.

In order to have a SimpleDelegator-compatible Mash, you can use the `PermissiveRespondTo` extension to make Mash respond to anything.

```ruby
class PermissiveMash < Hashie::Mash
  include Hashie::Extensions::Mash::PermissiveRespondTo
end

mash = PermissiveMash.new(a: 1)
mash.respond_to? :b  #=> true
```

This comes at the cost of approximately 20% performance for initialization and setters and 19KB of permanent memory growth for each such class that you create.

### SafeAssignment

This extension can be mixed into a Mash to guard the attempted overwriting of methods by property setters. When mixed in, the Mash will raise an `ArgumentError` if you attempt to write a property with the same name as an existing method.

```ruby
class SafeMash < ::Hashie::Mash
  include Hashie::Extensions::Mash::SafeAssignment
end

safe_mash = SafeMash.new
safe_mash.zip   = 'Test' # => ArgumentError
safe_mash[:zip] = 'test' # => still ArgumentError
```

### TransformKeys

Include `Hashie::Extensions::Mash::TransformKeys` and configure `transform_keys_with` with a callable or block to normalize string and symbol keys. The transformer receives a string and must return a string; other key types are unchanged.

```ruby
class LowercaseMash < Hashie::Mash
  include Hashie::Extensions::Mash::TransformKeys
  transform_keys_with(&:downcase)
end

mash = LowercaseMash.new('User' => { 'NAME' => 'Ada' })
mash.user.name # => 'Ada'
mash.USER.NAME # => 'Ada'
```

Normalization applies to reads and writes, including nested Mashes and hashes inside arrays. Subclasses inherit the callable but can replace it without changing their parent or siblings. Without a callable, ordinary Mash key conversion is retained. Configure the transformer before creating instances, keep it free of side effects, and make it idempotent: transforming an already-normalized key must return the same key. When input keys normalize to the same key, the last assignment wins. Transformer exceptions propagate; non-string results raise `TypeError`.

### UnderscoreKeys

Include `Hashie::Extensions::Mash::UnderscoreKeys` to normalize camelCase, PascalCase, and hyphenated keys to lowercase underscore names. It uses `TransformKeys`, including its nested conversion and subclass configuration behavior.

```ruby
class UnderscoreMash < Hashie::Mash
  include Hashie::Extensions::Mash::UnderscoreKeys
end

mash = UnderscoreMash.new('updatedAt' => 'today', 'created-at' => 'tomorrow')
mash.updatedAt  # => 'today'
mash.updated_at # => 'today'
mash.created_at # => 'tomorrow'
mash.to_h      # => { 'updated_at' => 'today', 'created_at' => 'tomorrow' }
```

Acronym boundaries are split: `HTTPServer` becomes `http_server`, and `GitHub` becomes `git_hub`. There is no acronym registry or ActiveSupport dependency. Spaces and punctuation other than hyphens are retained, so this does not guarantee method-safe names. Non-text keys are unchanged. If keys normalize to the same name, the last assignment wins. Use `transform_keys_with` to replace this policy with custom normalization.

### SymbolizeKeys

This extension can be mixed into a Mash to change the default behavior of converting keys to strings. After mixing this extension into a Mash, the Mash will convert all string keys to symbols. It can be useful to use with keywords argument, which required symbol keys.

```ruby
class SymbolizedMash < ::Hashie::Mash
  include Hashie::Extensions::Mash::SymbolizeKeys
end

symbol_mash = SymbolizedMash.new
symbol_mash['test'] = 'value'
symbol_mash.test  #=> 'value'
symbol_mash.to_h  #=> {test: 'value'}

def example(test:)
  puts test
end

example(symbol_mash) #=> value
```

There is a major benefit and coupled with a major trade-off to this decision (at least on older Rubies). As a benefit, by using symbols as keys, you will be able to use the implicit conversion of a Mash via the `#to_hash` method to destructure (or splat) the contents of a Mash out to a block. This can be handy for doing iterations through the Mash's keys and values, as follows:

```ruby
symbol_mash = SymbolizedMash.new(id: 123, name: 'Rey')
symbol_mash.each do |key, value|
  # key is :id, then :name
  # value is 123, then 'Rey'
end
```

However, on Rubies less than 2.0, this means that every key you send to the Mash will generate a symbol. Since symbols are not garbage-collected on older versions of Ruby, this can cause a slow memory leak when using a symbolized Mash with data generated from user input.

### DefineAccessors

This extension can be mixed into a Mash so it makes it behave like `OpenStruct`. It reduces the overhead of `method_missing?` magic by lazily defining field accessors when they're requested.

```ruby
class MyHash < ::Hashie::Mash
  include Hashie::Extensions::Mash::DefineAccessors
end

mash = MyHash.new
MyHash.method_defined?(:foo=) #=> false
mash.foo = 123
MyHash.method_defined?(:foo=) #=> true

MyHash.method_defined?(:foo) #=> false
mash.foo #=> 123
MyHash.method_defined?(:foo) #=> true
```

You can also extend the existing mash without defining a class:

```ruby
mash = ::Hashie::Mash.new.with_accessors!
```

### StrictKeyAccess

This extension can be mixed into a Mash to raise a `KeyError` for any key that is not set, instead of returning `nil`. It's aware of Mash's special suffixed methods (`?`, `!`, `_` and `=`), which all continue to work as normal. Since nested Hashes are converted into instances of the same Mash class, this behavior automatically applies to nested Mashes as well.

```ruby
class StrictMash < Hashie::Mash
  include Hashie::Extensions::Mash::StrictKeyAccess
end

mash = StrictMash.new(name: 'Bob', address: { city: 'Springfield' })
mash.name           #=> 'Bob'
mash.age            #=> KeyError: key not found: `age`

mash.name?          #=> true
mash.age?           #=> false

mash.address.city   #=> 'Springfield'
mash.address.zip    #=> KeyError: key not found: `zip`
```


### RequiredKeys

This extension can be mixed into a Mash to require specific keys to be set (non-nil) when constructing an instance, while still allowing arbitrary, undeclared keys to be assigned - unlike `Hashie::Dash`, which only allows setting pre-declared properties.

```ruby
class PersonMash < ::Hashie::Mash
  include Hashie::Extensions::Mash::RequiredKeys

  required_keys :name, :email
end

PersonMash.new(email: 'bob@example.com')
# => ArgumentError: the following keys are required: `name`

person = PersonMash.new(name: 'Bob', email: 'bob@example.com')
person.age = 42 # arbitrary, undeclared keys are still allowed
```

## Dash

Dash is an extended Hash that has a discrete set of defined properties and only those properties may be set on the hash. Additionally, you can set defaults for each property. You can also flag a property as required. Required properties will raise an exception if unset. Another option is message for required properties, which allow you to add custom messages for required property. A property with a proc value will be evaluated lazily upon retrieval.

You can also conditionally require certain properties by passing a Proc or Symbol. If a Proc is provided, it will be run in the context of the Dash instance. If a Symbol is provided, the value returned for the property or method of the same name will be evaluated. The property will be required if the result of the conditional is truthy.

```ruby
class Person < Hashie::Dash
  property :name, required: true
  property :age, required: true, message: 'must be set.'
  property :email
  property :phone, required: -> { email.nil? }, message: 'is required if email is not set.'
  property :pants, required: :weekday?, message: 'are only required on weekdays.'
  property :occupation, default: 'Rubyist'
  property :genome

  def weekday?
    [ Time.now.saturday?, Time.now.sunday? ].none?
  end
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
p.genome = -> { Genome.sequence } # Some expensive operation
p.genome       # => 'GATTACA'
```

Properties defined as symbols are not the same thing as properties defined as strings.

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

If you would like to update a Dash and use any default values set in the case of a `nil` value, use `#update_attributes!`.

```ruby
class WithDefaults < Hashie::Dash
  property :description, default: 'none'
end

dash = WithDefaults.new
dash.description  #=> 'none'

dash.description = 'You committed one of the classic blunders!'
dash.description  #=> 'You committed one of the classic blunders!'

dash.description = nil
dash.description  #=> nil

dash.description = 'Only slightly less known is ...'
dash.update_attributes!(description: nil)
dash.description  #=> 'none'
```

### Validations with ActiveModel

Include [ActiveModel::Validations](https://api.rubyonrails.org/classes/ActiveModel/Validations.html) in a Dash subclass to validate property values with standard validators or custom `validate` methods. Add `gem 'activemodel'` to your application's Gemfile unless Rails already provides it; ActiveModel is optional and is not a Hashie runtime dependency.

```ruby
require 'logger'
require 'active_model'
require 'hashie'

class Article < Hashie::Dash
  include ActiveModel::Validations

  property :title, required: true

  validates :title, presence: true, length: { maximum: 15 }
end

article = Article.new(title: 'Hello')
article.valid? # => true

article.title = 'A title that is too long' # assignment succeeds
article.valid? # => false
article.errors[:title] # => ["is too long (maximum is 15 characters)"]

article.title = ''
article.valid? # => false
article.errors[:title] # => ["can't be blank"]

article.title = 'Short title'
article.valid? # => true
article.errors.empty? # => true
```

Call `valid?` explicitly after constructing or changing the Dash. Including `ActiveModel::Validations` does not automatically validate on initialization or assignment, reject invalid values, or roll back changes; `valid?` returns a boolean and populates `errors`.

Dash's `required: true` is a separate non-nil constraint: omitting `title` during initialization or assigning `nil` raises `ArgumentError` immediately, without calling `valid?`. It permits an empty string, whereas ActiveModel's `presence` validator reports blank values when `valid?` runs. Leave off `required: true` if missing or nil values should be collected as validation errors instead of raising.

### Potential Gotchas

Because Dashes are subclasses of the built-in Ruby Hash class, the double-splat operator takes the Dash as-is without any conversion. This can lead to strange behavior when you use the double-splat operator on a Dash as the first part of a keyword list or built Hash. For example:

```ruby
class Foo < Hashie::Dash
  property :bar
end

foo = Foo.new(bar: 'baz')      #=> {:bar=>"baz"}
qux = { **foo, quux: 'corge' } #=> {:bar=> "baz", :quux=>"corge"}
qux.is_a?(Foo)                 #=> true
qux[:quux]
#=> raise NoMethodError, "The property 'quux' is not defined for Foo."
qux.key?(:quux) #=> true
```

You can work around this problem in two ways:

1. Call `#to_h` on the resulting object to convert it into a Hash.
2. Use the double-splat operator on the Dash as the last argument in the Hash literal. This will cause the resulting object to be a Hash instead of a Dash, thereby circumventing the problem.

```ruby
qux = { **foo, quux: 'corge' }.to_h #=> {:bar=> "baz", :quux=>"corge"}
qux.is_a?(Hash)                     #=> true
qux[:quux]                          #=> "corge"

qux = { quux: 'corge', **foo } #=> {:quux=>"corge", :bar=> "baz"}
qux.is_a?(Hash)                #=> true
qux[:quux]                     #=> "corge"
```

### PropertyTranslation

The `Hashie::Extensions::Dash::PropertyTranslation` mixin extends a Dash with
the ability to remap keys from a source hash.

Property translation is useful when you need to read data from another
application -- such as a Java API -- where the keys are named differently from
Ruby conventions.

```ruby
class PersonHash < Hashie::Dash
  include Hashie::Extensions::Dash::PropertyTranslation

  property :first_name, from: :firstName
  property :last_name, from: :lastName
  property :first_name, from: :f_name
  property :last_name, from: :l_name
end

person = PersonHash.new(firstName: 'Michael', l_name: 'Bleigh')
person[:first_name]  #=> 'Michael'
person[:last_name]   #=> 'Bleigh
```

You can also use a lambda to translate the value. This is particularly useful
when you want to ensure the type of data you're wrapping.

```ruby
class DataModelHash < Hashie::Dash
  include Hashie::Extensions::Dash::PropertyTranslation

  property :id, transform_with: ->(value) { value.to_i }
  property :created_at, from: :created, with: ->(value) { Time.parse(value) }
end

model = DataModelHash.new(id: '123', created: '2014-04-25 22:35:28')
model.id.class          #=> Integer (Fixnum if you are using Ruby 2.3 or lower)
model.created_at.class  #=> Time
```

### Mash and Rails 4 Strong Parameters

To enable compatibility with Rails 4 use the [hashie-forbidden_attributes](https://github.com/Maxim-Filimonov/hashie-forbidden_attributes) gem.

### Coercion

If you want to use `Hashie::Extensions::Coercion` together with `Dash` then
you may probably want to use `Hashie::Extensions::Dash::Coercion` instead.
This extension automatically includes `Hashie::Extensions::Coercion`
and also adds a convenient `:coerce` option to `property` so you can define coercion in one line
instead of using `property` and `coerce_key` separate:

```ruby
class UserHash < Hashie::Dash
  include Hashie::Extensions::Coercion

  property :id
  property :posts

  coerce_key :posts, Array[PostHash]
end
```

This is the same as:

```ruby
class UserHash < Hashie::Dash
  include Hashie::Extensions::Dash::Coercion

  property :id
  property :posts, coerce: Array[PostHash]
end
```

### PredefinedValues

The `Hashie::Extensions::Dash::PredefinedValues` mixin extends a Dash with
the ability to accept predefined values on a property.

```ruby
class UserHash < Hashie::Dash
  include Hashie::Extensions::Dash::PredefinedValues

  property :gender, values: %i[male female prefer_not_to_say]
  property :age, values: (0..150)
end
```

## Trash

A Trash is a Dash that allows you to translate keys on initialization. It mixes
in the PropertyTranslation mixin by default and is used like so:

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
result.id.class         # => Integer (Fixnum if you are using Ruby 2.3 or lower)
result.created_at.class # => Time
```

Multiple properties can share a source key to flatten a nested hash. Combine indifferent access with `IgnoreUndeclared` to accept string or symbol input keys and ignore unrelated fields:

```ruby
class FlattenedPerson < Hashie::Trash
  include Hashie::Extensions::IgnoreUndeclared
  include Hashie::Extensions::IndifferentAccess

  property :first_name, from: :name, transform_with: ->(name) { name['first'] }
  property :last_name, from: :name, transform_with: ->(name) { name['last'] }
end

person = FlattenedPerson.new('name' => { 'first' => 'First', 'last' => 'Last' }, 'extra' => true)
person.first_name # => 'First'
person.last_name  # => 'Last'
```

## Clash

Clash is a Chainable Lazy Hash that allows you to easily construct complex hashes using method notation chaining. This will allow you to use a more action-oriented approach to building options hashes.

Essentially, a Clash is a generalized way to provide much of the same kind of "chainability" that libraries like Arel or Rails 2.x's named_scopes provide.

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

Clash supports YAML round-trips, preserving stored data, named subclasses, and parent links used by `_end!`. Only deserialize trusted YAML with Ruby object loading enabled (`Psych.unsafe_load` on modern Psych); ordinary safe loading does not permit arbitrary Ruby classes.

## Rash

Rash is a Hash whose keys can be Regexps or Ranges, which will map many input keys to a value.

A good use case for the Rash is an URL router for a web framework, where URLs need to be mapped to actions; the Rash's keys match URL patterns, while the values call the action which handles the URL.

If the Rash's value is a `proc`, the `proc` will be automatically called with the regexp's MatchData (matched groups) as a block argument.

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

### Auto-Optimized

**Note:** The Rash is automatically optimized every 500 accesses (which means that it sorts the list of Regexps, putting the most frequently matched ones at the beginning).

If this value is too low or too high for your needs, you can tune it by setting: `rash.optimize_every = n`.

## Mascot
[![eierlegende Wollmilchsau](./mascot.svg)](https://en.wiktionary.org/wiki/eierlegende_Wollmilchsau) Meet Hashie's "official" mascot, the [eierlegende Wollmilchsau](https://en.wiktionary.org/wiki/eierlegende_Wollmilchsau)!

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)

## Copyright

Copyright (c) 2009-2020 [Intridea, Inc.](http://intridea.com), and [contributors](https://github.com/hashie/hashie/graphs/contributors).

MIT License. See [LICENSE](LICENSE) for details.
