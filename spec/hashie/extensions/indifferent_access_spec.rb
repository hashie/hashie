require 'spec_helper'

describe Hashie::Extensions::IndifferentAccess do
  class IndifferentHashWithMergeInitializer < Hash
    include Hashie::Extensions::MergeInitializer
    include Hashie::Extensions::IndifferentAccess

    class << self
      alias_method :build, :new
    end
  end

  class IndifferentHashWithArrayInitializer < Hash
    include Hashie::Extensions::IndifferentAccess

    class << self
      alias_method :build, :[]
    end
  end

  class IndifferentHashWithTryConvertInitializer < Hash
    include Hashie::Extensions::IndifferentAccess

    class << self
      alias_method :build, :try_convert
    end
  end

  shared_examples_for 'hash with indifferent access' do
    it 'is able to access via string or symbol' do
      h = subject.build(abc: 123)
      h[:abc].should eq 123
      h['abc'].should eq 123
    end

    describe '#values_at' do
      it 'indifferently finds values' do
        h = subject.build(:foo => 'bar', 'baz' => 'qux')
        h.values_at('foo', :baz).should eq %w(bar qux)
      end
    end

    describe '#fetch' do
      it 'works like normal fetch, but indifferent' do
        h = subject.build(foo: 'bar')
        h.fetch(:foo).should eq h.fetch('foo')
        h.fetch(:foo).should eq 'bar'
      end
    end

    describe '#delete' do
      it 'deletes indifferently' do
        h = subject.build(:foo => 'bar', 'baz' => 'qux')
        h.delete('foo')
        h.delete(:baz)
        h.should be_empty
      end
    end

    describe '#key?' do
      let(:h) { subject.build(foo: 'bar') }

      it 'finds it indifferently' do
        h.should be_key(:foo)
        h.should be_key('foo')
      end

      %w(include? member? has_key?).each do |key_alias|
        it "is aliased as #{key_alias}" do
          h.send(key_alias.to_sym, :foo).should be(true)
          h.send(key_alias.to_sym, 'foo').should be(true)
        end
      end
    end

    describe '#update' do
      let(:h) { subject.build(foo: 'bar') }

      it 'allows keys to be indifferent still' do
        h.update(baz: 'qux')
        h['foo'].should eq 'bar'
        h['baz'].should eq 'qux'
      end

      it 'recursively injects indifference into sub-hashes' do
        h.update(baz: { qux: 'abc' })
        h['baz']['qux'].should eq 'abc'
      end

      it 'does not change the ancestors of the injected object class' do
        h.update(baz: { qux: 'abc' })
        Hash.new.should_not be_respond_to(:indifferent_access?)
      end
    end

    describe '#replace' do
      let(:h) { subject.build(foo: 'bar').replace(bar: 'baz', hi: 'bye') }

      it 'returns self' do
        h.should be_a(subject)
      end

      it 'removes old keys' do
        [:foo, 'foo'].each do |k|
          h[k].should be_nil
          h.key?(k).should be_false
        end
      end

      it 'creates new keys with indifferent access' do
        [:bar, 'bar', :hi, 'hi'].each { |k| h.key?(k).should be_true }
        h[:bar].should eq 'baz'
        h['bar'].should eq 'baz'
        h[:hi].should eq 'bye'
        h['hi'].should eq 'bye'
      end
    end

    describe '#try_convert' do
      describe 'with conversion' do
        let(:h) { subject.try_convert(foo: 'bar') }

        it 'is a subject' do
          h.should be_a(subject)
        end
      end

      describe 'without conversion' do
        let(:h) { subject.try_convert('{ :foo => bar }') }

        it 'is nil' do
          h.should be_nil
        end
      end
    end
  end

  describe 'with merge initializer' do
    subject { IndifferentHashWithMergeInitializer }
    it_should_behave_like 'hash with indifferent access'
  end

  describe 'with array initializer' do
    subject { IndifferentHashWithArrayInitializer }
    it_should_behave_like 'hash with indifferent access'
  end

  describe 'with try convert initializer' do
    subject { IndifferentHashWithTryConvertInitializer }
    it_should_behave_like 'hash with indifferent access'
  end
end
