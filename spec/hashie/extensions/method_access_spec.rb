require 'spec_helper'

describe Hashie::Extensions::MethodReader do
  class ReaderHash < Hash
    def initialize(hash = {}); self.update(hash) end
    include Hashie::Extensions::MethodReader
  end
  subject{ ReaderHash }

  it 'should read string keys from the method' do
    subject.new('awesome' => 'sauce').awesome.should == 'sauce'
  end

  it 'should read symbol keys from the method' do
    subject.new(:awesome => 'sauce').awesome.should == 'sauce'
  end

  it 'should read nil and false values out properly' do
    h = subject.new(:nil => nil, :false => false)
    h.nil.should == nil
    h.false.should == false
  end

  it 'should raise a NoMethodError for undefined keys' do
    lambda{ subject.new.awesome }.should raise_error(NoMethodError)
  end

  describe '#respond_to?' do
    it 'should be true for string keys' do
      subject.new('awesome' => 'sauce').should be_respond_to(:awesome)
    end

    it 'should be true for symbol keys' do
      subject.new(:awesome => 'sauce').should be_respond_to(:awesome)
    end

    it 'should be false for non-keys' do
      subject.new.should_not be_respond_to(:awesome)
    end
  end
end

describe Hashie::Extensions::MethodWriter do
  class WriterHash < Hash
    include Hashie::Extensions::MethodWriter
  end
  subject{ WriterHash.new }

  it 'should write from a method call' do
    subject.awesome = 'sauce'
    subject['awesome'].should == 'sauce'
  end

  it 'should convert the key using the #convert_key method' do
    subject.stub!(:convert_key).and_return(:awesome)
    subject.awesome = 'sauce'
    subject[:awesome].should == 'sauce'
  end

  it 'should still NoMethodError on non equals-ending methods' do
    lambda{ subject.awesome }.should raise_error(NoMethodError)
  end

  it 'should #respond_to? properly' do
    subject.should be_respond_to(:abc=)
    subject.should_not be_respond_to(:abc)
  end
end

describe Hashie::Extensions::MethodQuery do
  class QueryHash < Hash
    def initialize(hash = {}); self.update(hash) end
    include Hashie::Extensions::MethodQuery
  end
  subject{ QueryHash }
  
  it 'should be true for non-nil string key values' do
    subject.new('abc' => 123).should be_abc
  end

  it 'should be true for non-nil symbol key values' do
    subject.new(:abc => 123).should be_abc
  end

  it 'should be false for nil key values' do
    subject.new(:abc => false).should_not be_abc
  end

  it 'should raise a NoMethodError for non-set keys' do
    lambda{ subject.new.abc? }.should raise_error(NoMethodError)
  end

  it 'should respond_to? for existing string keys' do
    subject.new('abc' => 'def').should be_respond_to('abc?')
  end

  it 'should respond_to? for existing symbol keys' do
    subject.new(:abc => 'def').should be_respond_to(:abc?)
  end

  it 'should not respond_to? for non-existent keys' do
    subject.new.should_not be_respond_to('abc?')
  end
end

describe Hashie::Extensions::MethodAccess do
  it 'should include all of the other method mixins' do
    klass = Class.new(Hash)
    klass.send :include, Hashie::Extensions::MethodAccess
    (klass.ancestors & [Hashie::Extensions::MethodReader, Hashie::Extensions::MethodWriter, Hashie::Extensions::MethodQuery]).size.should == 3
  end
end
