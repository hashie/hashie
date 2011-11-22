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
  end

  describe '.coerce_value' do
    context 'with :strict => true' do
      it 'should coerce any value of the exact right class' do
        subject.coerce_value String, Coercable
        
        instance[:foo] = "bar"
        instance[:bar] = "bax"
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
