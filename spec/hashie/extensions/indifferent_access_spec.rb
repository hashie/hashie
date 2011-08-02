require 'spec_helper'

describe Hashie::Extensions::IndifferentAccess do
  class IndifferentHash < Hash
    include Hashie::Extensions::MergeInitializer
    include Hashie::Extensions::IndifferentAccess
  end
  subject{ IndifferentHash }

  it 'should be able to access via string or symbol' do
    h = subject.new(:abc => 123)
    h[:abc].should == 123
    h['abc'].should == 123
  end

  describe '#values_at' do
    it 'should indifferently find values' do
      h = subject.new(:foo => 'bar', 'baz' => 'qux')
      h.values_at('foo', :baz).should == %w(bar qux)
    end
  end

  describe '#fetch' do
    it 'should work like normal fetch, but indifferent' do
      h = subject.new(:foo => 'bar')
      h.fetch(:foo).should == h.fetch('foo')
      h.fetch(:foo).should == 'bar'
    end
  end

  describe '#delete' do
    it 'should delete indifferently' do
      h = subject.new(:foo => 'bar', 'baz' => 'qux')
      h.delete('foo')
      h.delete(:baz)
      h.should be_empty
    end
  end

  describe '#key?' do
    it 'should find it indifferently' do
      h = subject.new(:foo => 'bar')
      h.should be_key(:foo)
      h.should be_key('foo')
    end
  end

  describe '#update' do
    subject{ IndifferentHash.new(:foo => 'bar') }
    it 'should allow keys to be indifferent still' do
      subject.update(:baz => 'qux')
      subject['foo'].should == 'bar'
      subject['baz'].should == 'qux'
    end

    it 'should recursively inject indifference into sub-hashes' do
      subject.update(:baz => {:qux => 'abc'})
      subject['baz']['qux'].should == 'abc'
    end

    it 'should not change the ancestors of the injected object class' do
      subject.update(:baz => {:qux => 'abc'})
      Hash.new.should_not be_respond_to(:indifferent_access?)
    end
  end
end
