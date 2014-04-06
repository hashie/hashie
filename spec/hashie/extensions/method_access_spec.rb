require 'spec_helper'

describe Hashie::Extensions::MethodReader do
  class ReaderHash < Hash
    include Hashie::Extensions::MethodReader

    def initialize(hash = {})
      update(hash)
    end
  end

  subject { ReaderHash }

  it 'reads string keys from the method' do
    subject.new('awesome' => 'sauce').awesome.should eq 'sauce'
  end

  it 'reads symbol keys from the method' do
    subject.new(awesome: 'sauce').awesome.should eq 'sauce'
  end

  it 'reads nil and false values out properly' do
    h = subject.new(nil: nil, false: false)
    h.nil.should eq nil
    h.false.should eq false
  end

  it 'raises a NoMethodError for undefined keys' do
    lambda { subject.new.awesome }.should raise_error(NoMethodError)
  end

  describe '#respond_to?' do
    it 'is true for string keys' do
      subject.new('awesome' => 'sauce').should be_respond_to(:awesome)
    end

    it 'is true for symbol keys' do
      subject.new(awesome: 'sauce').should be_respond_to(:awesome)
    end

    it 'is false for non-keys' do
      subject.new.should_not be_respond_to(:awesome)
    end
  end
end

describe Hashie::Extensions::MethodWriter do
  class WriterHash < Hash
    include Hashie::Extensions::MethodWriter
  end

  subject { WriterHash.new }

  it 'writes from a method call' do
    subject.awesome = 'sauce'
    subject['awesome'].should eq 'sauce'
  end

  it 'converts the key using the #convert_key method' do
    subject.stub!(:convert_key).and_return(:awesome)
    subject.awesome = 'sauce'
    subject[:awesome].should eq 'sauce'
  end

  it 'raises NoMethodError on non equals-ending methods' do
    lambda { subject.awesome }.should raise_error(NoMethodError)
  end

  it '#respond_to? correctly' do
    subject.should be_respond_to(:abc=)
    subject.should_not be_respond_to(:abc)
  end
end

describe Hashie::Extensions::MethodQuery do
  class QueryHash < Hash
    include Hashie::Extensions::MethodQuery

    def initialize(hash = {})
      update(hash)
    end
  end

  subject { QueryHash }

  it 'is true for non-nil string key values' do
    subject.new('abc' => 123).should be_abc
  end

  it 'is true for non-nil symbol key values' do
    subject.new(abc: 123).should be_abc
  end

  it 'is false for nil key values' do
    subject.new(abc: false).should_not be_abc
  end

  it 'raises a NoMethodError for non-set keys' do
    lambda { subject.new.abc? }.should raise_error(NoMethodError)
  end

  it '#respond_to? for existing string keys' do
    subject.new('abc' => 'def').should be_respond_to('abc?')
  end

  it '#respond_to? for existing symbol keys' do
    subject.new(abc: 'def').should be_respond_to(:abc?)
  end

  it 'does not #respond_to? for non-existent keys' do
    subject.new.should_not be_respond_to('abc?')
  end
end

describe Hashie::Extensions::MethodAccess do
  it 'includes all of the other method mixins' do
    klass = Class.new(Hash)
    klass.send :include, Hashie::Extensions::MethodAccess
    (klass.ancestors & [Hashie::Extensions::MethodReader, Hashie::Extensions::MethodWriter, Hashie::Extensions::MethodQuery]).size.should eq 3
  end
end
