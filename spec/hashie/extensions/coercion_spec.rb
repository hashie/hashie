require 'spec_helper'

describe Hashie::Extensions::Coercion do
  class Initializable
    attr_reader :coerced, :value

    def initialize(obj, coerced = false)
      @coerced = coerced
      @value = obj.class.to_s
    end

    def coerced?
      !!@coerced
    end
  end

  class Coercable < Initializable
    def self.coerce(obj)
      new(obj, true)
    end
  end

  before(:each) do
    class ExampleCoercableHash < Hash
      include Hashie::Extensions::Coercion
      include Hashie::Extensions::MergeInitializer
    end
  end

  subject { ExampleCoercableHash }

  let(:instance) { subject.new }

  describe '#coerce_key' do
    it { expect(subject).to be_respond_to(:coerce_key) }

    it 'runs through coerce on a specified key' do
      subject.coerce_key :foo, Coercable

      instance[:foo] = 'bar'
      expect(instance[:foo]).to be_coerced
    end

    it 'supports an array of keys' do
      subject.coerce_keys :foo, :bar, Coercable

      instance[:foo] = 'bar'
      instance[:bar] = 'bax'
      expect(instance[:foo]).to be_coerced
      expect(instance[:bar]).to be_coerced
    end

    it 'supports coercion for Array' do
      subject.coerce_key :foo, Array[Coercable]

      instance[:foo] = %w('bar', 'bar2')
      expect(instance[:foo]).to all(be_coerced)
      expect(instance[:foo]).to be_a(Array)
    end

    it 'supports coercion for Set' do
      subject.coerce_key :foo, Set[Coercable]

      instance[:foo] = Set.new(%w('bar', 'bar2'))
      expect(instance[:foo]).to all(be_coerced)
      expect(instance[:foo]).to be_a(Set)
    end

    it 'supports coercion for Set of primitive' do
      subject.coerce_key :foo, Set[Initializable]

      instance[:foo] = %w('bar', 'bar2')
      expect(instance[:foo].map(&:value)).to all(eq 'String')
      expect(instance[:foo]).to be_none { |v| v.coerced? }
      expect(instance[:foo]).to be_a(Set)
    end

    it 'supports coercion for Hash' do
      subject.coerce_key :foo, Hash[Coercable => Coercable]

      instance[:foo] = { 'bar_key' => 'bar_value', 'bar2_key' => 'bar2_value' }
      expect(instance[:foo].keys).to all(be_coerced)
      expect(instance[:foo].values).to all(be_coerced)
      expect(instance[:foo]).to be_a(Hash)
    end

    it 'supports coercion for Hash with primitive as value' do
      subject.coerce_key :foo, Hash[Coercable => Initializable]

      instance[:foo] = { 'bar_key' => '1', 'bar2_key' => '2' }
      expect(instance[:foo].values.map(&:value)).to all(eq 'String')
      expect(instance[:foo].keys).to all(be_coerced)
    end

    it 'calls #new if no coerce method is available' do
      subject.coerce_key :foo, Initializable

      instance[:foo] = 'bar'
      expect(instance[:foo].value).to eq 'String'
      expect(instance[:foo]).not_to be_coerced
    end

    it 'coerces when the merge initializer is used' do
      subject.coerce_key :foo, Coercable
      instance = subject.new(foo: 'bar')

      expect(instance[:foo]).to be_coerced
    end

    context 'when #replace is used' do
      before { subject.coerce_key :foo, :bar, Coercable }

      let(:instance) do
        subject.new(foo: 'bar').replace(foo: 'foz', bar: 'baz', hi: 'bye')
      end

      it 'coerces relevant keys' do
        expect(instance[:foo]).to be_coerced
        expect(instance[:bar]).to be_coerced
        expect(instance[:hi]).not_to respond_to(:coerced?)
      end

      it 'sets correct values' do
        expect(instance[:hi]).to eq 'bye'
      end
    end

    context 'when used with a Mash' do
      class UserMash < Hashie::Mash
      end
      class TweetMash < Hashie::Mash
        include Hashie::Extensions::Coercion
        coerce_key :user, UserMash
      end

      it 'coerces with instance initialization' do
        tweet = TweetMash.new(user: { email: 'foo@bar.com' })
        expect(tweet[:user]).to be_a(UserMash)
      end

      it 'coerces when setting with attribute style' do
        tweet = TweetMash.new
        tweet.user = { email: 'foo@bar.com' }
        expect(tweet[:user]).to be_a(UserMash)
      end

      it 'coerces when setting with string index' do
        tweet = TweetMash.new
        tweet['user'] = { email: 'foo@bar.com' }
        expect(tweet[:user]).to be_a(UserMash)
      end

      it 'coerces when setting with symbol index' do
        tweet = TweetMash.new
        tweet[:user] = { email: 'foo@bar.com' }
        expect(tweet[:user]).to be_a(UserMash)
      end
    end

    context 'when used with a Trash' do
      class UserTrash < Hashie::Trash
        property :email
      end
      class TweetTrash < Hashie::Trash
        include Hashie::Extensions::Coercion

        property :user, from: :user_data
        coerce_key :user, UserTrash
      end

      it 'coerces with instance initialization' do
        tweet = TweetTrash.new(user_data: { email: 'foo@bar.com' })
        expect(tweet[:user]).to be_a(UserTrash)
      end
    end

    context 'when used with IndifferentAccess to coerce a Mash' do
      class MyHash < Hash
        include Hashie::Extensions::Coercion
        include Hashie::Extensions::IndifferentAccess
        include Hashie::Extensions::MergeInitializer
      end

      class UserHash < MyHash
      end

      class TweetHash < MyHash
        coerce_key :user, UserHash
      end

      it 'coerces with instance initialization' do
        tweet = TweetHash.new(user: Hashie::Mash.new(email: 'foo@bar.com'))
        expect(tweet[:user]).to be_a(UserHash)
      end

      it 'coerces when setting with string index' do
        tweet = TweetHash.new
        tweet['user'] = Hashie::Mash.new(email: 'foo@bar.com')
        expect(tweet[:user]).to be_a(UserHash)
      end

      it 'coerces when setting with symbol index' do
        tweet = TweetHash.new
        tweet[:user] = Hashie::Mash.new(email: 'foo@bar.com')
        expect(tweet[:user]).to be_a(UserHash)
      end
    end
  end

  describe '#coerce_value' do
    context 'with strict: true' do
      it 'coerces any value of the exact right class' do
        subject.coerce_value String, Coercable

        instance[:foo] = 'bar'
        instance[:bar] = 'bax'
        instance[:hi]  = :bye
        expect(instance[:foo]).to be_coerced
        expect(instance[:bar]).to be_coerced
        expect(instance[:hi]).not_to respond_to(:coerced?)
      end

      it 'coerces values from a #replace call' do
        subject.coerce_value String, Coercable

        instance[:foo] = :bar
        instance.replace(foo: 'bar', bar: 'bax')
        expect(instance[:foo]).to be_coerced
        expect(instance[:bar]).to be_coerced
      end

      it 'does not coerce superclasses' do
        klass = Class.new(String)
        subject.coerce_value klass, Coercable

        instance[:foo] = 'bar'
        expect(instance[:foo]).not_to be_kind_of(Coercable)
        instance[:foo] = klass.new
        expect(instance[:foo]).to be_kind_of(Coercable)
      end
    end
  end

  after(:each) do
    Object.send(:remove_const, :ExampleCoercableHash)
  end
end
