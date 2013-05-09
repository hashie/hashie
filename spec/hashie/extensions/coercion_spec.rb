require 'spec_helper'

describe Hashie::Extensions::Coercion do
  class Initializable
    def initialize(obj, coerced = false)
      @coerced = coerced
      @value = obj.class.to_s
    end
    def coerced?; @coerced end
    attr_reader :value
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
  let(:instance){ subject.new }

  describe '.coerce_key' do
    it { subject.should be_respond_to(:coerce_key) }

    it 'should run through coerce on a specified key' do
      subject.coerce_key :foo, Coercable

      instance[:foo] = "bar"
      instance[:foo].should be_coerced
    end

    it "should support an array of keys" do
      subject.coerce_keys :foo, :bar, Coercable

      instance[:foo] = "bar"
      instance[:bar] = "bax"
      instance[:foo].should be_coerced
      instance[:bar].should be_coerced
    end

    it 'should just call #new if no coerce method is available' do
      subject.coerce_key :foo, Initializable

      instance[:foo] = "bar"
      instance[:foo].value.should == "String"
      instance[:foo].should_not be_coerced
    end

    it "should coerce when the merge initializer is used" do
      subject.coerce_key :foo, Coercable
      instance = subject.new(:foo => "bar")

      instance[:foo].should be_coerced
    end

    context 'when #replace is used' do
      before { subject.coerce_key :foo, :bar, Coercable }

      let(:instance) do
        subject.new(:foo => "bar").
          replace(:foo => "foz", :bar => "baz", :hi => "bye")
      end

      it "should coerce relevant keys" do
        instance[:foo].should be_coerced
        instance[:bar].should be_coerced
        instance[:hi].should_not respond_to(:coerced?)
      end

      it "should set correct values" do
        instance[:hi].should == "bye"
      end
    end

    context "when used with a Mash" do
      class UserMash < Hashie::Mash
      end
      class TweetMash < Hashie::Mash
        include Hashie::Extensions::Coercion
        coerce_key :user, UserMash
      end

      it "should coerce with instance initialization" do
        tweet = TweetMash.new(:user => {:email => 'foo@bar.com'})
        tweet[:user].should be_a(UserMash)
      end

      it "should coerce when setting with attribute style" do
        tweet = TweetMash.new
        tweet.user = {:email => 'foo@bar.com'}
        tweet[:user].should be_a(UserMash)
      end

      it "should coerce when setting with string index" do
        tweet = TweetMash.new
        tweet['user'] = {:email => 'foo@bar.com'}
        tweet[:user].should be_a(UserMash)
      end

      it "should coerce when setting with symbol index" do
        tweet = TweetMash.new
        tweet[:user] = {:email => 'foo@bar.com'}
        tweet[:user].should be_a(UserMash)
      end
    end
  end

  describe '.coerce_value' do
    context 'with :strict => true' do
      it 'should coerce any value of the exact right class' do
        subject.coerce_value String, Coercable

        instance[:foo] = "bar"
        instance[:bar] = "bax"
        instance[:hi]  = :bye
        instance[:foo].should be_coerced
        instance[:bar].should be_coerced
        instance[:hi].should_not respond_to(:coerced?)
      end

      it 'should coerce values from a #replace call' do
        subject.coerce_value String, Coercable

        instance[:foo] = :bar
        instance.replace(:foo => "bar", :bar => "bax")
        instance[:foo].should be_coerced
        instance[:bar].should be_coerced
      end

      it 'should not coerce superclasses' do
        klass = Class.new(String)
        subject.coerce_value klass, Coercable

        instance[:foo] = "bar"
        instance[:foo].should_not be_kind_of(Coercable)
        instance[:foo] = klass.new
        instance[:foo].should be_kind_of(Coercable)
      end
    end
  end

  after(:each) do
    Object.send(:remove_const, :ExampleCoercableHash)
  end
end
