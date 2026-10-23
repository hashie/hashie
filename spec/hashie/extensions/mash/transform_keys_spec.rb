# frozen_string_literal: true

require 'spec_helper'

describe Hashie::Extensions::Mash::TransformKeys do
  let(:klass) do
    Class.new(Hashie::Mash) do
      include Hashie::Extensions::Mash::TransformKeys
      transform_keys_with(&:downcase)
    end
  end

  it 'normalizes reads, writes, fetch, membership, deletion and merge' do
    mash = klass.new('NAME' => 'Ada')
    expect(mash.NAME).to eq('Ada')
    expect(mash[:Name]).to eq('Ada')
    expect(mash.fetch('NAME')).to eq('Ada')
    expect(mash.key?(:NAME)).to be true
    mash.Name = 'Grace'
    expect(mash.values_at(:NAME)).to eq(['Grace'])
    merged = mash.merge('NAME' => 'Lin')
    expect(merged.name).to eq('Lin')
    expect(mash.name).to eq('Grace')
    mash.merge!('NAME' => 'Lin')
    expect(mash.delete(:NAME)).to eq('Lin')
    expect(mash.key?(:NAME)).to be false
  end

  it 'normalizes nested hashes and hashes in arrays without changing the input' do
    source = { 'USER' => { 'NAME' => 'Ada' }, 'ITEMS' => [{ 'CODE' => 1 }] }
    mash = klass.new(source)
    expect(mash.user.name).to eq('Ada')
    expect(mash.items.first.code).to eq(1)
    expect(mash.user).to be_instance_of(klass)
    expect(source['USER'].keys).to eq(['NAME'])
  end

  it 'uses last assignment for collisions and leaves non-text keys unchanged' do
    mash = klass.new('NAME' => 1, name: 2, 42 => 'answer', nil => 'nil')
    expect(mash.to_h).to eq('name' => 2, 42 => 'answer', nil => 'nil')
    expect(mash[42]).to eq('answer')
  end

  it 'inherits configuration without changing the parent or siblings when overridden' do
    child = Class.new(klass)
    sibling = Class.new(klass)
    child.transform_keys_with(&:upcase)
    expect(child.new(name: 1).keys).to eq(['NAME'])
    expect(klass.new(NAME: 1).keys).to eq(['name'])
    expect(sibling.new(NAME: 1).keys).to eq(['name'])
  end

  it 'keeps ordinary Mash behavior when no transformer is configured' do
    unconfigured = Class.new(Hashie::Mash) { include Hashie::Extensions::Mash::TransformKeys }
    expect(unconfigured.new(Name: 1).to_h).to eq('Name' => 1)
  end

  it 'rejects invalid configuration and invalid transformer results explicitly' do
    expect { Class.new(Hash) { include Hashie::Extensions::Mash::TransformKeys } }
      .to raise_error(ArgumentError, /must descend from Hashie::Mash/)
    expect { klass.transform_keys_with }.to raise_error(ArgumentError)
    expect { klass.transform_keys_with('invalid') }.to raise_error(ArgumentError)
    expect { klass.transform_keys_with(->(key) { key }) { |key| key } }
      .to raise_error(ArgumentError)
    klass.transform_keys_with(->(_) { nil })
    expect { klass.new(name: 1) }.to raise_error(TypeError, 'key transformer must return a String')
  end
end
