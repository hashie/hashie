require 'spec_helper'

describe Hash do
  it 'is convertible to a Hashie::Mash' do
    mash = Hashie::Hash[some: 'hash'].to_mash
    mash.is_a?(Hashie::Mash).should be_true
    mash.some.should eq 'hash'
  end

  it '#stringify_keys! turns all keys into strings' do
    hash = Hashie::Hash[:a => 'hey', 123 => 'bob']
    hash.stringify_keys!
    hash.should eq Hashie::Hash['a' => 'hey', '123' => 'bob']
  end

  it '#stringify_keys returns a hash with stringified keys' do
    hash = Hashie::Hash[:a => 'hey', 123 => 'bob']
    stringified_hash = hash.stringify_keys
    hash.should eq Hashie::Hash[:a => 'hey', 123 => 'bob']
    stringified_hash.should eq Hashie::Hash['a' => 'hey', '123' => 'bob']
  end

  it '#to_hash returns a hash with stringified keys' do
    hash = Hashie::Hash['a' => 'hey', 123 => 'bob', 'array' => [1, 2, 3]]
    stringified_hash = hash.to_hash
    stringified_hash.should eq('a' => 'hey', '123' => 'bob', 'array' => [1, 2, 3])
  end

  it '#to_hash with symbolize_keys set to true returns a hash with symbolized keys' do
    hash = Hashie::Hash['a' => 'hey', 123 => 'bob', 'array' => [1, 2, 3]]
    symbolized_hash = hash.to_hash(symbolize_keys: true)
    symbolized_hash.should eq(:a => 'hey', :"123" => 'bob', :array => [1, 2, 3])
  end
end
