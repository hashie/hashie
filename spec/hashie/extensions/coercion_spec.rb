require 'spec_helper'

describe Hashie::Extensions::Coercion do
  class NotInitializable
    private_class_method :new
  end

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
    context 'nesting' do
      class RootCoercableHash < Hash
        include Hashie::Extensions::Coercion
        include Hashie::Extensions::MergeInitializer
        coerce_key :foo, Integer
      end

      class NestedCoercableHash < RootCoercableHash
        include Hashie::Extensions::Coercion
        include Hashie::Extensions::MergeInitializer
        coerce_key :foo, Integer
      end

      subject { RootCoercableHash }
      let(:instance) { subject.new }

      it 'coeces nested objects' do
        subject.coerce_key :nested, NestedCoercableHash

        instance[:nested] = { foo: '123' }
        expect(instance[:nested]).to be_a(NestedCoercableHash)
        expect(instance[:nested][:foo]).to be_an(Integer)
        expect(instance[:nested][:foo]).to eq('123')
      end
    end

    it { expect(subject).to be_respond_to(:coerce_key) }

    it 'runs through coerce on a specified key' do
      subject.coerce_key :foo, Coercable

      instance[:foo] = 'bar'
      expect(instance[:foo]).to be_coerced
    end

    it 'skips unnecessary coercions' do
      subject.coerce_key :foo, Coercable

      instance[:foo] = Coercable.new('bar')
      expect(instance[:foo]).to_not be_coerced
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

    context 'coercing core types' do
      def test_coercion(literal, target_type, coerce_method)
        subject.coerce_key :foo, target_type
        instance[:foo] = literal
        expect(instance[:foo]).to be_a(target_type)
        expect(instance[:foo]).to eq(literal.send(coerce_method))
      end

      RSpec.shared_examples 'coerces from numeric types' do |target_type, coerce_method|
        it "coerces from String to #{target_type} via #{coerce_method}" do
          test_coercion '2.0', target_type, coerce_method
        end

        it "coerces from Integer to #{target_type} via #{coerce_method}" do
          # Fixnum
          test_coercion 2, target_type, coerce_method
          # Bignum
          test_coercion 12_345_667_890_987_654_321, target_type, coerce_method
        end

        it "coerces from Rational to #{target_type} via #{coerce_method}" do
          test_coercion Rational(2, 3), target_type, coerce_method
        end
      end

      RSpec.shared_examples 'coerces from alphabetical types' do |target_type, coerce_method|
        it "coerces from String to #{target_type} via #{coerce_method}" do
          test_coercion 'abc', target_type, coerce_method
        end

        it "coerces from Symbol to #{target_type} via #{coerce_method}" do
          test_coercion :abc, target_type, coerce_method
        end
      end

      include_examples 'coerces from numeric types', Integer, :to_i
      include_examples 'coerces from numeric types', Float, :to_f
      include_examples 'coerces from numeric types', String, :to_s

      include_examples 'coerces from alphabetical types', String, :to_s
      include_examples 'coerces from alphabetical types', Symbol, :to_sym

      it 'can coerce String to Rational when possible' do
        test_coercion '2/3', Rational, :to_r
      end

      it 'can coerce String to Complex when possible' do
        test_coercion '2/3+3/4i', Complex, :to_c
      end

      it 'coerces collections with core types' do
        subject.coerce_key :foo, Hash[String => String]

        instance[:foo] = {
          abc: 123,
          xyz: 987
        }
        expect(instance[:foo]).to eq(
                                       'abc' => '123',
                                       'xyz' => '987'
                                     )
      end

      it 'can coerce booleans via a proc' do
        subject.coerce_key :foo, ->(v) do
          case v
          when String
            return !!(v =~ /^(true|t|yes|y|1)$/i)
          when Numeric
            return !v.to_i.zero?
          else
            return v == true
          end
        end

        true_values = [true, 'true', 't', 'yes', 'y', '1', 1, -1]
        false_values = [false, 'false', 'f', 'no', 'n', '0', 0]

        true_values.each do |v|
          instance[:foo] = v
          expect(instance[:foo]).to be_a(TrueClass)
        end
        false_values.each do |v|
          instance[:foo] = v
          expect(instance[:foo]).to be_a(FalseClass)
        end
      end

      it 'raises errors for non-coercable types' do
        subject.coerce_key :foo, NotInitializable
        expect { instance[:foo] = 'true' }.to raise_error(Hashie::Extensions::Coercion::CoercionError, /NotInitializable is not a coercable type/)
      end

      pending 'can coerce false' do
        subject.coerce_key :foo, Initializable

        instance[:foo] = false
        expect(instance[:foo]).to be_coerced
        expect(instance[:foo].value).to eq(false)
      end

      pending 'can coerce nil' do
        subject.coerce_key :foo, Initializable

        instance[:foo] = nil
        expect(instance[:foo]).to be_coerced
        expect(instance[:foo].value).to be_nil
      end
    end

    it 'does not coerce unnecessarily' do
      subject.coerce_key :foo, Float

      instance[:foo] = 2.0
      expect(instance[:foo]).to be_a(Float)
      expect(instance[:foo]).to eq(2.0)
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
        expect(tweet['user']).to be_a(UserMash)
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

    context 'core types' do
      it 'coerces String to Integer when possible' do
        subject.coerce_value String, Integer

        instance[:foo] = '2'
        instance[:bar] = '2.7'
        instance[:hi] = 'hi'
        expect(instance[:foo]).to be_a(Integer)
        expect(instance[:foo]).to eq(2)
        expect(instance[:bar]).to be_a(Integer)
        expect(instance[:bar]).to eq(2)
        expect(instance[:hi]).to be_a(Integer)
        expect(instance[:hi]).to eq(0) # not what I expected...
      end

      it 'coerces non-numeric from String to Integer' do
        # This was surprising, but I guess it's "correct"
        # unless there is a stricter `to_i` alternative
        subject.coerce_value String, Integer
        instance[:hi] = 'hi'
        expect(instance[:hi]).to be_a(Integer)
        expect(instance[:hi]).to eq(0)
      end

      it 'raises a TypeError when coercion is not possible' do
        subject.coerce_value Fixnum, Symbol
        expect { instance[:hi] = 1 }.to raise_error(Hashie::Extensions::Coercion::CoercionError, /Cannot coerce property :hi from Fixnum to Symbol/)
      end

      pending 'coerces Integer to String' do
        subject.coerce_value Integer, String

        instance[:foo] = 2
        instance[:bar] = 2.7
        expect(instance[:foo]).to be_a(String)
        expect(instance[:foo]).to eq('2')
        expect(instance[:bar]).to be_a(String)
        expect(instance[:bar]).to eq('2.0')
      end

      pending 'coerces Numeric to String' do
        subject.coerce_value Numeric, String

        {
          fixnum: 2,
          bignum: 12_345_667_890_987_654_321,
          float: 2.7,
          rational: Rational(2, 3),
          complex: Complex(1)
        }.each do | k, v |
          instance[k] = v
          expect(instance[k]).to be_a(String)
          expect(instance[k]).to eq(v.to_s)
        end
      end
    end
  end

  after(:each) do
    Object.send(:remove_const, :ExampleCoercableHash)
  end
end
