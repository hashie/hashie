Upgrading Hashie
================

### Upgrading to 3.0

#### Compatibility with Rails 4 Strong Parameters

Version 2.1 introduced support to prevent default Rails 4 mass-assignment protection behavior. This was [issue #89](https://github.com/intridea/hashie/issues/89), resolved in [#104](https://github.com/intridea/hashie/pull/104). In version 2.2 this behavior has been removed in [#147](https://github.com/intridea/hashie/pull/147) in favor of a mixin and finally extracted into a separate gem in Hashie 3.0.

To enable 2.1 compatible behavior with Rails 4, use the [hashie_rails](http://rubygems.org/gems/hashie_rails) gem.

```
gem 'hashie_rails'
```

See [#154](https://github.com/intridea/hashie/pull/154) and [Mash and Rails 4 Strong Parameters](README.md#mash-and-rails-4-strong-parameters) for more details.

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

It was not possible to achieve the behavior of preserving keys, as described in [issue #151](https://github.com/intridea/hashie/issues/151).

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

See [#152](https://github.com/intridea/hashie/pull/152) for more information.


