require 'spec_helper'

describe Hashie::Extensions::KeyConversion do
  subject do
    klass = Class.new(::Hash)
    klass.send :include, Hashie::Extensions::KeyConversion
    klass
  end
  let(:instance){ subject.new }

  describe '#stringify_keys!' do
    it 'should convert keys to strings' do
      instance[:abc] = 'abc'
      instance[123] = '123'
      instance.stringify_keys!
      (instance.keys & %w(abc 123)).size.should == 2
    end

    it 'should do deep conversion within nested hashes' do
      instance[:ab] = subject.new
      instance[:ab][:cd] = subject.new
      instance[:ab][:cd][:ef] = 'abcdef'
      instance.stringify_keys!
      instance.should == {'ab' => {'cd' => {'ef' => 'abcdef'}}}
    end

    it 'should do deep conversion within nested arrays' do
      instance[:ab] = []
      instance[:ab] << subject.new
      instance[:ab] << subject.new
      instance[:ab][0][:cd] = 'abcd'
      instance[:ab][1][:ef] = 'abef'
      instance.stringify_keys!
      instance.should == {'ab' => [{'cd' => 'abcd'}, {'ef' => 'abef'}]}
    end

    it 'should return itself' do
      instance.stringify_keys!.should == instance
    end
  end

  describe '#stringify_keys' do
    it 'should convert keys to strings' do
      instance[:abc] = 'def'
      copy = instance.stringify_keys
      copy['abc'].should == 'def'
    end

    it 'should not alter the original' do
      instance[:abc] = 'def'
      copy = instance.stringify_keys
      instance.keys.should == [:abc]
      copy.keys.should == %w(abc)
    end
  end

  describe '#symbolize_keys!' do
    it 'should convert keys to symbols' do
      instance['abc'] = 'abc'
      instance['def'] = 'def'
      instance.symbolize_keys!
      (instance.keys & [:abc, :def]).size.should == 2
    end

    it 'should do deep conversion within nested hashes' do
      instance['ab'] = subject.new
      instance['ab']['cd'] = subject.new
      instance['ab']['cd']['ef'] = 'abcdef'
      instance.symbolize_keys!
      instance.should == {:ab => {:cd => {:ef => 'abcdef'}}}
    end

    it 'should do deep conversion within nested arrays' do
      instance['ab'] = []
      instance['ab'] << subject.new
      instance['ab'] << subject.new
      instance['ab'][0]['cd'] = 'abcd'
      instance['ab'][1]['ef'] = 'abef'
      instance.symbolize_keys!
      instance.should == {:ab => [{:cd => 'abcd'}, {:ef => 'abef'}]}
    end

    it 'should return itself' do
      instance.symbolize_keys!.should == instance
    end
  end

  describe '#symbolize_keys' do
    it 'should convert keys to symbols' do
      instance['abc'] = 'def'
      copy = instance.symbolize_keys
      copy[:abc].should == 'def'
    end

    it 'should not alter the original' do
      instance['abc'] = 'def'
      copy = instance.symbolize_keys
      instance.keys.should == ['abc']
      copy.keys.should == [:abc]
    end
  end
end
