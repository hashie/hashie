# frozen_string_literal: true

require 'spec_helper'

describe Hashie::Extensions::DeepMergeInitializer do
  let(:hash_class) do
    Class.new(Hash) do
      include Hashie::Extensions::DeepMergeInitializer
    end
  end

  it 'initializes without arguments' do
    expect(hash_class.new).to eq({})
  end

  it 'preserves keys and scalar values' do
    expect(hash_class.new('name' => 'Bob', enabled: false, missing: nil))
      .to eq('name' => 'Bob', enabled: false, missing: nil)
  end

  it 'converts hashes at every depth to the containing class' do
    hash = hash_class.new(child: { grandchild: { name: 'Bob' } })
    expect(hash[:child]).to be_an_instance_of(hash_class)
    expect(hash[:child][:grandchild]).to be_an_instance_of(hash_class)
    expect(hash[:child][:grandchild][:name]).to eq('Bob')
  end

  it 'converts empty hashes' do
    expect(hash_class.new(child: {})[:child]).to be_an_instance_of(hash_class)
  end

  it 'converts hashes nested in arrays and arrays within arrays' do
    hash = hash_class.new(children: [{ name: 'Bob' }, [{ name: 'Alice' }], nil, false])
    expect(hash[:children][0]).to be_an_instance_of(hash_class)
    expect(hash[:children][1][0]).to be_an_instance_of(hash_class)
    expect(hash[:children]).to eq([{ name: 'Bob' }, [{ name: 'Alice' }], nil, false])
  end

  it 'does not mutate frozen source hashes or arrays' do
    child = { name: 'Bob' }.freeze
    array = [child].freeze
    input = { child: child, children: array }.freeze
    hash = hash_class.new(input)
    expect(hash).to eq(input)
    expect(hash[:child]).not_to equal(child)
    expect(hash[:children]).not_to equal(array)
    expect(hash[:children][0]).not_to equal(child)
  end

  it 'leaves scalar objects unchanged' do
    value = Object.new
    expect(hash_class.new(value: value)[:value]).to equal(value)
  end

  it 'reconstructs existing hash subclasses without modifying them' do
    child = hash_class.new(name: 'Bob')
    hash = hash_class.new(child: child)
    expect(hash[:child]).to be_an_instance_of(hash_class)
    expect(hash[:child]).not_to equal(child)
    expect(child).to eq(name: 'Bob')
  end

  it 'uses the concrete subclass for nested hashes' do
    subclass = Class.new(hash_class)
    expect(subclass.new(child: {})[:child]).to be_an_instance_of(subclass)
  end

  it 'propagates a default value to nested hashes' do
    hash = hash_class.new({ child: {}, children: [{}] }, 'missing')
    expect(hash[:unknown]).to eq('missing')
    expect(hash[:child][:unknown]).to eq('missing')
    expect(hash[:children][0][:unknown]).to eq('missing')
  end

  it 'preserves false as a default value' do
    hash = hash_class.new({ child: {} }, false)
    expect(hash[:unknown]).to be(false)
    expect(hash[:child][:unknown]).to be(false)
  end

  it 'propagates a default block to nested hashes' do
    hash = hash_class.new(child: {}, children: [{}]) { |target, key| target[key] = [] }
    expect(hash[:unknown]).to eq([])
    expect(hash[:child][:unknown]).to eq([])
    expect(hash[:children][0][:unknown]).to eq([])
    expect(hash[:unknown]).not_to equal(hash[:child][:unknown])
  end

  it 'preserves Hash rejection of a default value combined with a block' do
    expect { hash_class.new({}, false) { [] } }.to raise_error(ArgumentError)
  end

  it 'does not convert later assignments' do
    hash = hash_class.new
    child = { name: 'Bob' }
    hash[:child] = child
    expect(hash[:child]).to equal(child)
    expect(hash[:child]).to be_an_instance_of(Hash)
  end

  it 'rejects invalid initializer input' do
    expect { hash_class.new(nil) }.to raise_error(NoMethodError)
  end

  context 'with method and indifferent access' do
    let(:hash_class) do
      Class.new(Hash) do
        include Hashie::Extensions::DeepMergeInitializer
        include Hashie::Extensions::IndifferentAccess
        include Hashie::Extensions::MethodAccess
      end
    end

    it 'supports nested method access from issue 347' do
      hash = hash_class.new(foo: { bar: 1 })
      expect(hash.foo.bar).to eq(1)
      expect(hash[:foo][:bar]).to eq(1)
      expect(hash['foo']['bar']).to eq(1)
      expect(hash.foo).to be_an_instance_of(hash_class)
    end

    it 'supports method access for hashes inside frozen arrays' do
      hash = hash_class.new(items: [{ name: 'Bob' }.freeze].freeze)
      expect(hash.items.first.name).to eq('Bob')
      expect(hash.items.first).to be_an_instance_of(hash_class)
    end
  end

  context 'with coercion' do
    let(:hash_class) do
      Class.new(Hash) do
        include Hashie::Extensions::DeepMergeInitializer
        include Hashie::Extensions::Coercion

        coerce_key :count, Integer
      end
    end

    it 'uses subclass writers for both root and nested values' do
      hash = hash_class.new(count: '1', child: { count: '2' })
      expect(hash[:count]).to eq(1)
      expect(hash[:child][:count]).to eq(2)
    end
  end
end
