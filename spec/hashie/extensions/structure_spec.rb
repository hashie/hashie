require 'spec_helper'

describe Hashie::Extensions::Structure do
  class StructuredHash < ::Hash
    include Hashie::Extensions::Structure
    property :first
    property :second, default: 'foo'
  end

  describe '#[]=' do
    it 'allows setting permitted keys' do
      hash = StructuredHash.new
      hash[:first] = 1
      hash[:first].should == 1
    end

    it 'doesn\'t allow setting non-permitted keys' do
      hash = StructuredHash.new
      expect { hash[:bogus] = 123 }.to raise_error(KeyError)
    end
  end

  describe 'defaults' do
    it 'sets default values for unset keys' do
      hash = StructuredHash.new
      hash[:second].should == 'foo'
    end

    it 'overrides default values with setters' do
      hash = StructuredHash.new
      hash[:second] = 'bar'
      hash[:second].should == 'bar'
    end

    it 'works for #fetch too' do
      hash = StructuredHash.new
      hash.fetch(:second).should == 'foo'
    end

    it 'dups defaults' do
      hash = StructuredHash.new
      another_hash = StructuredHash.new
      hash[:second].object_id.should_not == another_hash[:second].object_id
    end
  end

  describe '#fetch' do
    it 'allows getting permitted keys' do
      hash = StructuredHash.new
      hash[:first] = :foo
      hash.fetch(:first).should == :foo
    end

    it 'raises on non-permitted keys' do
      expect { StructuredHash.new.fetch(:bar, 1) }.to raise_error(KeyError)
    end

    it 'allows giving default value as an arg' do
      StructuredHash.new.fetch(:first, :foo).should == :foo
    end

    it 'allows giving default value as a block' do
      StructuredHash.new.fetch(:first) { :foo }.should == :foo
    end

    it 'raises when key is missing and no default value provided' do
      expect { StructuredHash.new.fetch(:first) }.to raise_error(KeyError)
    end
  end

  describe '#merge' do
    it 'allows merging hash of same class' do
      hash = StructuredHash.new
      hash[:first] = 1
      another_hash = StructuredHash.new
      hash[:first] = 2
      merged = hash.merge(another_hash)
      merged[:first].should == 2
    end

    it 'allows merging hash of different class, provided it won\'t have forbidden values' do
      hash = StructuredHash.new
      hash[:first] = 1
      merged = hash.merge(first: 2)
      merged[:first].should == 2
    end

    it 'doesn\'t allow merging hash with forbidden values' do
      expect { StructuredHash.new.merge(foo: :bar) }.to raise_error(KeyError)
    end

    it 'allows giving a block for collision resolution' do
      hash = StructuredHash.new
      hash[:first] = 'foo'
      result = hash.merge(first: 'bar') { |key, v1, v2| "#{v1}_#{v2}" }
      result[:first].should == 'foo_bar'
    end
  end

  describe '#merge!' do
    it 'allows merging hash of same class' do
      hash = StructuredHash.new
      hash[:first] = 1
      another_hash = StructuredHash.new
      hash[:first] = 2
      hash.merge!(another_hash)
      hash[:first].should == 2
    end

    it 'allows merging hash of different class, provided it won\'t have forbidden values' do
      hash = StructuredHash.new
      hash[:first] = 1
      hash.merge!(first: 2)
      hash[:first].should == 2
    end

    it 'doesn\'t allow merging hash with forbidden values' do
      expect { StructuredHash.new.merge!(foo: :bar) }.to raise_error(KeyError)
    end

    it 'allows giving a block for collision resolution' do
      hash = StructuredHash.new
      hash[:first] = 'foo'
      hash.merge!(first: 'bar') { |key, v1, v2| "#{v1}_#{v2}" }
      hash[:first].should == 'foo_bar'
    end
  end

  describe 'inheritance' do
    class StructuredHashDescendant < StructuredHash
      property :third, default: :bar
    end

    it 'keeps superclass keys' do
      hash = StructuredHashDescendant.new
      hash[:first] = :baz
      hash[:second].should == 'foo'
    end

    it 'doesn\'t prevent from setting new keys' do
      StructuredHashDescendant.new.fetch(:third).should == :bar
    end

    it 'doesn\'t accidentally modify superclass' do
      expect { StructuredHash.new.fetch(:third) }.to raise_error(KeyError)
    end
  end
end
