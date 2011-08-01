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
