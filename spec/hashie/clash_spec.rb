require 'spec_helper'

describe Hashie::Clash do
  it 'is able to set an attribute via method_missing' do
    subject.foo('bar')
    expect(subject[:foo]).to eq 'bar'
  end

  it 'is able to set multiple attributes' do
    subject.foo('bar').baz('wok')
    expect(subject).to eq(foo: 'bar', baz: 'wok')
  end

  it 'converts multiple arguments into an array' do
    subject.foo(1, 2, 3)
    expect(subject[:foo]).to eq [1, 2, 3]
  end

  it 'is able to use bang notation to create a new Clash on a key' do
    subject.foo!
    expect(subject[:foo]).to be_kind_of(Hashie::Clash)
  end

  it 'is able to chain onto the new Clash when using bang notation' do
    subject.foo!.bar('abc').baz(123)
    expect(subject).to eq(foo: { bar: 'abc', baz: 123 })
  end

  it 'is able to jump back up to the parent in the chain with #_end!' do
    subject.foo!.bar('abc')._end!.baz(123)
    expect(subject).to eq(foo: { bar: 'abc' }, baz: 123)
  end

  it 'merges rather than replaces existing keys' do
    subject.where(abc: 'def').where(hgi: 123)
    expect(subject).to eq(where: { abc: 'def', hgi: 123 })
  end

  it 'is able to replace all of its own keys with #replace' do
    subject.foo(:bar).hello(:world)
    expect(subject.replace(baz: 123, hgi: 123)).to eq(baz: 123, hgi: 123)
    expect(subject).to eq(baz: 123, hgi: 123)
    expect(subject[:foo]).to be_nil
    expect(subject[:hello]).to be_nil
  end

  it 'merges multiple bang notation calls' do
    subject.where!.foo(123)
    subject.where!.bar(321)
    expect(subject).to eq(where: { foo: 123, bar: 321 })
  end

  it 'raises an exception when method is missing' do
    expect { subject.boo }.to raise_error(NoMethodError)
  end

  it 'is able to set the id key via method_missing' do
    subject.id('123')
    expect(subject[:id]).to eq '123'
  end

  it 'is able to chain into an existing plain hash value' do
    subject[:foo] = Hashie::Hash[bar: 'abc']
    subject.foo!.baz(123)
    expect(subject).to eq(foo: { bar: 'abc', baz: 123 })
    expect(subject[:foo]).to be_kind_of(Hashie::Clash)
  end

  it 'raises a ChainError when chaining into a non-hash key' do
    subject.foo('bar')
    expect { subject.foo! }.to raise_error(Hashie::Clash::ChainError, 'Tried to chain into a non-hash key.')
  end

  describe '#respond_to?' do
    it 'is true for bang methods when the key is unset' do
      expect(subject.respond_to?(:foo!)).to be true
    end

    it 'is true for bang methods when the key is a Hash' do
      subject[:foo] = Hashie::Hash[bar: 'abc']
      expect(subject.respond_to?(:foo!)).to be true
    end

    it 'is false for bang methods when the key is not chainable' do
      subject.foo('bar')
      expect(subject.respond_to?(:foo!)).to be false
    end

    it 'is true for any non-bang method' do
      expect(subject.respond_to?(:anything)).to be true
    end
  end

  describe 'when inherited' do
    subject { Class.new(described_class).new }

    it 'bang nodes are instances of a subclass' do
      subject.where!.foo(123)
      expect(subject[:where]).to be_instance_of(subject.class)
    end

    it 'merged nodes are instances of a subclass' do
      subject.where(abc: 'def').where(hgi: 123)
      expect(subject[:where]).to be_instance_of(subject.class)
    end
  end
end
