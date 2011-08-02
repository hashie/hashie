require 'spec_helper'

describe Hashie::Extensions::MergeInitializer do
  class MergeInitializerHash < Hash; include Hashie::Extensions::MergeInitializer end
  subject{ MergeInitializerHash }

  it 'should initialize fine with no arguments' do
    subject.new.should == {}
  end

  it 'should initialize with a hash' do
    subject.new(:abc => 'def').should == {:abc => 'def'}
  end

  it 'should initialize with a hash and a default' do
    h = subject.new({:abc => 'def'}, 'bar')
    h[:foo].should == 'bar'
    h[:abc].should == 'def'
  end
end
