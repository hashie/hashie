Upgrading Hashie
================

### Upgrading to 6.0.0

#### YAML loading no longer evaluates ERB by default

`Hashie::Mash.load` now defaults to `Hashie::Extensions::Parsers::YamlParser`, introduced in #625, rather than `YamlErbParser`. This is a breaking change for configuration files containing ERB: template expressions are no longer evaluated and may remain literal strings or cause YAML parsing errors.

For trusted files that require ERB interpolation, explicitly select the previous parser:

```ruby
Hashie::Mash.load('trusted-settings.yml', parser: Hashie::Extensions::Parsers::YamlErbParser)
```

Do not use `YamlErbParser` with untrusted input: it executes Ruby before parsing YAML. Both parsers still use `YAML.safe_load`, and `permitted_classes`, `permitted_symbols`, and `aliases` retain their existing meanings. Custom parsers, frozen results, and path-based caching are unchanged. Because cached results are keyed only by path, use separate Mash subclasses if the same file needs different parser policies.

See [#631](https://github.com/hashie/hashie/pull/631) for more information.

#### DeepMerge preserves incoming hash subclasses

`Hashie::Extensions::DeepMerge` now preserves the class, instance state, and defaults of incoming nested hashes by default. New destinations use `source.dup.clear` instead of `{}`, so required constructor arguments and required-property Dashes do not require an empty constructor. Existing destination hashes keep their own types; source hashes are never cleared.

This is a breaking change for code relying on incoming subclasses becoming plain hashes. Preserved subclasses may enforce custom assignment rules or expose different lookup behavior. Applications requiring plain nested hashes must explicitly normalize their input hash values before merging.

The policy applies at every incoming nested-hash level for both `deep_merge` and `deep_merge!`, including hashes inside arrays. Custom hashes must support duplication, clearing, and assignment into the copied hash.

See [#632](https://github.com/hashie/hashie/pull/632) for more information.

#### DeepMerge value copying

`Hashie::Extensions::DeepMerge` now recursively copies hashes, arrays, and strings on both sides, but retains other values by identity. It no longer calls `Hashie::Utils.safe_dup` on receiver leaves or `deep_dup` on incoming leaves. ActiveRecord models therefore retain their identity, primary keys, and persistence state without a custom policy.

This is a breaking change: arbitrary receiver objects are now shared, incoming strings are now copied even without ActiveSupport, and receiver arrays are copied recursively rather than shallowly. Arrays still replace conflicting values rather than merging element by element. Incoming hashes inside arrays preserve their subclasses, and existing receiver container subclasses retain their types.

If your application needs independent copies of domain objects, explicitly copy them according to their own APIs before merging. Do not assume `deep_merge` clones an entire object graph. `deep_merge!` keeps existing receiver values in place, and conflict-block results are still stored unchanged. Cyclic inputs are not supported.

See [#633](https://github.com/hashie/hashie/pull/633) for more information.

#### Mash preserves custom Hash values

Nested Hash subclasses other than Mash are now stored by identity instead of being converted into Mashes or copied. This applies to initialization, assignment, arrays, copying, replacement, and merges. Plain Hash values are still recursively converted, and existing Mash-specific copying behavior is unchanged.

Code relying on `mash.custom.some_key` for a custom Hash value must use that object's own API, such as `mash.custom[:some_key]`, or explicitly convert it with `Hashie::Mash.new(custom_hash)` before insertion. A custom Hash replaces an existing nested Mash during merge rather than recursively merging into it. Because custom values are shared, `dup` and `merge` no longer isolate mutations to them; explicitly copy such values when needed.

See [#637](https://github.com/hashie/hashie/pull/637) for more information.

#### Dash and Trash accessor collisions

Property declarations no longer replace existing methods, regardless of visibility. Read and write conflicting properties with brackets: use `dash[:class]` instead of `dash.class`, and `dash[:count]` instead of `dash.count`. The latter methods retain their normal Ruby/Hash behavior. The same rule applies to translated source writers; use `trash[:source] = value` if `source=` already exists. Existing custom accessors are preserved; required and predefined-value validation now reads stored property values through brackets rather than invoking those accessors.

See [#639](https://github.com/hashie/hashie/pull/639) for more information.

#### Internal helper names

Private and protected implementation helpers consistently use one leading underscore, including `_translations` (formerly `__translations`) and `_convert` (formerly `__convert`). Subclasses overriding renamed helpers must update those overrides and calls. Ruby callbacks, documented extension hooks such as `initialize_attributes`, `convert_key`, and `convert_value`, and public methods keep their existing names. The documented `__method` aliases created by `MethodAccessWithOverride` also remain unchanged; those expose overridden methods rather than internal helpers.

Recursive key-conversion helpers, `Hashie::Utils`' integer-class helper, and Clash's merge-storage helper are now private and use underscore-prefixed names. Mash suffix parsing, method-redefinition helpers, and indifferent-hash detection are also private rather than protected. Use the public conversion, builder, and accessor APIs instead of calling these helpers directly.

See [#639](https://github.com/hashie/hashie/pull/639) for more information.

#### DeepFind results

`deep_find_all` and its alias `deep_select` now return `[]` instead of `nil` when no matches exist, matching `Enumerable#find_all`. Replace no-match checks such as `result.nil?` or `if result` with `result.empty?` or `result.any?`. Fallbacks such as `deep_find_all(:key) || []` are no longer necessary. `deep_find` and `deep_detect` still return `nil` when no match exists; matching values, including `nil`, remain in the results array.

See [#641](https://github.com/hashie/hashie/pull/641) for more information.

### Upgrading to 5.2.0

#### Safer YAML loading

`Hashie::Mash.load` continues to use `YamlErbParser` by default for compatibility, and that parser evaluates ERB. Do not load untrusted input with the default parser. To opt in to YAML parsing without ERB evaluation, pass `parser: Hashie::Extensions::Parsers::YamlParser`.

See [#625](https://github.com/hashie/hashie/pull/625) for more information.

#### Ruby version

Hashie now requires Ruby 3.0 or newer. Ruby 2.7 is no longer supported; upgrade Ruby before updating Hashie.

See [#622](https://github.com/hashie/hashie/pull/622) for more information.

#### Exception messages

Exception messages now begin with lowercase words, omit trailing periods, quote interpolated values with backticks, and use consistent wording. Exception classes and the conditions under which exceptions are raised have not changed.

Applications and tests that compare exact exception message strings must update their expectations.

See [#607](https://github.com/hashie/hashie/pull/607) for more information.

### Upgrading to 5.0.0

#### Mash initialization key conversion

Mash initialization now only converts to string keys which can be represented as symbols.

```ruby
Hashie::Mash.new(
  {foo: "bar"} => "baz",
  "1" => "one string",
  :"1" => "one sym",
  1 => "one num"
)

# Before
{"{:foo=>\"bar\"}"=>"baz", "1"=>"one num"}

# After
{{:foo=>"bar"}=>"baz", "1"=>"one sym", 1=>"one num"}
```

See [#521](https://github.com/hashie/hashie/pull/521) for more information.

#### Mash#dig with numeric keys

`Hashie::Mash#dig` no longer considers numeric keys for indifferent access.

```ruby
my_mash = Hashie::Mash.new("1" => "a") # => {"1"=>"a"}

my_mash.dig("1") # => "a"
my_mash.dig(:"1") # => "a"

# Before
my_mash.dig(1) # => "a"

# After
my_mash.dig(1) # => nil
```

See [#521](https://github.com/hashie/hashie/pull/521) for more information.

### Upgrading to 4.0.0

#### Non-destructive Hash methods called on Mash

The following non-destructive Hash methods called on Mash will now return an instance of the class it was called on.

| method            | ruby |
| ----------------- | ---- |
| #compact          |      |
| #invert           |      |
| #reject           |      |
| #select           |      |
| #slice            | 2.5  |
| #transform_keys   | 2.5  |
| #transform_values | 2.4  |

```ruby
class Parents < Hashie::Mash; end

parents = Parents.new(father: 'Dad', mother: 'Mom')
cool_parents = parents.transform_values { |v| v + v[-1] + 'io'}

p cool_parents

# before:
{"father"=>"Daddio", "mother"=>"Mommio"}
 => {"father"=>"Daddio", "mother"=>"Mommio"}

# after:
#<Parents father="Daddio" mother="Mommio">
=> {"father"=>"Dad", "mother"=>"Mom"}
```

This may make places where you had to re-make the Mash redundant, and may cause unintended side effects if your application was expecting a plain old ruby Hash.

See [#481](https://github.com/hashie/hashie/pull/481) for more information.

#### Ruby 2.6: Mash#merge and Mash#merge!

In Ruby > 2.6.0, Hashie now supports passing multiple hash and Mash objects to Mash#merge and Mash#merge!.

See [#481](https://github.com/hashie/hashie/pull/481) for more information.

#### Hashie::Mash::CannotDisableMashWarnings error class is removed

There shouldn't really be a case that anyone was relying on catching this specific error, but if so, they should change it to rescue Hashie::Extensions::KeyConflictWarning::CannotDisableMashWarnings

See [#488](https://github.com/hashie/hashie/pull/488) for more information.

### Upgrading to 3.7.0

#### Mash#load takes options

The `Hashie::Mash#load` method now accepts options, changing the interface of `Parser#initialize`. If you have a custom parser, you must update its `initialize` method.

For example, `Hashie::Extensions::Parsers::YamlErbParser` now accepts `permitted_classes`, `permitted_symbols` and `aliases` options.

Before:

```ruby
class Hashie::Extensions::Parsers::YamlErbParser
  def initialize(file_path)
    @file_path = file_path
  end
end
```

After:

```ruby
class Hashie::Extensions::Parsers::YamlErbParser
  def initialize(file_path, options = {})
    @file_path = file_path
    @options = options
  end
end
```

Options can now be passed into `Mash#load`.

```ruby
Mash.load(filename, permitted_classes: [])
```

See [#474](https://github.com/hashie/hashie/pull/474) for more information.

### Upgrading to 3.5.2

#### Disable logging in Mash subclasses

If you subclass `Hashie::Mash`, you can now disable the logging we do about overriding existing methods with keys. This looks like:

```ruby
class MyMash < Hashie::Mash
  disable_warnings
end
```

See [#395](https://github.com/hashie/hashie/pull/395) for more information.

### Upgrading to 3.4.7

#### Procs as default values for Dash

```ruby
class MyHash < Hashie::Dash
  property :time, default: -> { Time.now }
end
```

In versions < 3.4.7 `Time.now` will be evaluated when `time` property is accessed directly first time.
In version >= 3.4.7 `Time.now` is evaluated in time of object initialization.

See [#380](https://github.com/hashie/hashie/pull/380) for more information.

### Upgrading to 3.4.4

#### Mash subclasses and reverse_merge

```ruby
class MyMash < Hashie::Mash
end
```

In versions >= 3.4.4 `MyMash#reverse_merge` returns an instance of `MyMash` but in previous versions it was a `Hashie::Mash` instance.

See [#322](https://github.com/hashie/hashie/pull/322) for more information.

### Upgrading to 3.2.2

#### Testing if key defined

In versions <= 3.2.1 Hash object being questioned doesn't return a boolean value as it's mentioned in README.md

```ruby
class MyHash < Hash
  include Hashie::Extensions::MethodAccess
end

h = MyHash.new
h.abc = 'def'
h.abc  # => 'def'
h.abc? # => 'def'
```

In versions >= 3.2.2 it returns a boolean value

```ruby
h.abc? # => true
h.abb? # => false
```

See [#317](https://github.com/hashie/hashie/pull/317) for more information.

### Upgrading to 3.2.1

#### Possible coercion changes

The improvements made to coercions in version 3.2.1 [issue #200](https://github.com/hashie/hashie/pull/200) do not break the documented API, but are significant enough that changes may effect undocumented side-effects. Applications that depended on those side-effects will need to be updated.

**Change**: Type coercion no longer creates new objects if the input matches the target type. Previously coerced properties always resulted in the creation of a new object, even when it wasn't necessary. This had the effect of a `dup` or `clone` on coerced properties but not uncoerced ones.

If necessary, `dup` or `clone` your own objects. Do not assume Hashie will do it for you.

See [#200](https://github.com/hashie/hashie/pull/200) for more information.

**Change**: Failed coercion attempts now raise Hashie::CoercionError.

Hashie now raises a Hashie::CoercionError that details on the property that could not be coerced, the source and target type of the coercion, and the internal error. Previously only the internal error was raised.

Applications that were attempting to rescuing the internal errors should be updated to rescue Hashie::CoercionError instead.

See [#200](https://github.com/hashie/hashie/pull/200) for more information.

### Upgrading to 3.0

#### Compatibility with Rails 4 Strong Parameters

Version 2.1 introduced support to prevent default Rails 4 mass-assignment protection behavior. This was [issue #89](https://github.com/hashie/hashie/issues/89), resolved in [#104](https://github.com/hashie/hashie/pull/104). In version 2.2 this behavior has been removed in [#147](https://github.com/hashie/hashie/pull/147) in favor of a mixin and finally extracted into a separate gem in Hashie 3.0.

To enable 2.1 compatible behavior with Rails 4, use the [hashie_rails](http://rubygems.org/gems/hashie_rails) gem.

```
gem 'hashie_rails'
```

See [#154](https://github.com/hashie/hashie/pull/154) for more information. Also see [Mash and Rails 4 Strong Parameters](README.md#mash-and-rails-4-strong-parameters).

#### Key Conversions in Hashie::Dash and Hashie::Trash

Version 2.1 and older of Hashie::Dash and Hashie::Trash converted keys to strings by default. This is no longer the case in 2.2.

Consider the following code.

```ruby
class Person < Hashie::Dash
  property :name
end

p = Person.new(name: 'dB.')
```

Version 2.1 behaves as follows.

```ruby
p.name # => 'dB.'
p[:name] # => 'dB.'
p['name'] # => 'dB.'

# not what I put in
p.inspect # => { 'name' => 'dB.' }
p.to_hash # => { 'name' => 'dB.' }
```

It was not possible to achieve the behavior of preserving keys, as described in [issue #151](https://github.com/hashie/hashie/issues/151).

Version 2.2 does not perform this conversion by default.

```ruby
p.name # => 'dB.'
p[:name] # => 'dB.'
# p['name'] # => NoMethodError

p.inspect # => { :name => 'dB.' }
p.to_hash # => { :name => 'dB.' }
```

To enable behavior compatible with older versions, use `Hashie::Extensions::Dash::IndifferentAccess`.

```ruby
class Person < Hashie::Dash
  include Hashie::Extensions::Dash::IndifferentAccess
  property :name
end
```

See [#152](https://github.com/hashie/hashie/pull/152) for more information.

#### Key Conversions in Hashie::Hash#to_hash

Version 2.1 or older of Hash#to_hash converted keys to strings automatically.

```ruby
instance = Hashie::Hash[first: 'First', 'last' => 'Last']
instance.to_hash # => { "first" => 'First', "last" => 'Last' }
```

It was possible to symbolize keys by passing `:symbolize_keys`, however it was not possible to retrieve the hash with initial key values.

```ruby
instance.to_hash(symbolize_keys: true) # => { :first => 'First', :last => 'Last' }
instance.to_hash(stringify_keys: true) # => { "first" => 'First', "last" => 'Last' }
```

Version 2.2 no longer converts keys by default.

```ruby
instance = Hashie::Hash[first: 'First', 'last' => 'Last']
instance.to_hash # => { :first => 'First', "last" => 'Last' }
```

The behavior with `symbolize_keys` and `stringify_keys` is unchanged.

See [#152](https://github.com/hashie/hashie/pull/152) for more information.
