require 'spec_helper'

class DashTest < Hashie::Dash
  property :first_name
  property :email
  property :count, :default => 0
end

class Subclassed < DashTest
  property :last_name
end

describe Hashie::Dash do
  it 'should be a subclass of Hashie::Hash' do
    (Hashie::Dash < Hash).should be_true
  end

  it '#inspect should be ok!' do
    dash = DashTest.new
    dash.email = "abd@abc.com"
    dash.inspect.should == "<#DashTest count=0 email=\"abd@abc.com\" first_name=nil>"
  end

  describe ' creating properties' do
    it 'should add the property to the list' do
      DashTest.property :not_an_att
      DashTest.properties.include?('not_an_att').should be_true
    end

    it 'should create a method for reading the property' do
      DashTest.new.respond_to?(:first_name).should be_true
    end

    it 'should create a method for writing the property' do
      DashTest.new.respond_to?(:first_name=).should be_true
    end
  end

  describe 'reading properties' do
    it 'should raise an error when reading a non-existent property' do
      lambda{@dash['abc']}.should raise_error(NoMethodError)
    end
  end

  describe ' writing to properties' do
    before do
      @dash = DashTest.new
    end

    it 'should not be able to write to a non-existent property using []=' do
      lambda{@dash['abc'] = 123}.should raise_error(NoMethodError)
    end

    it 'should be able to write to an existing property using []=' do
      lambda{@dash['first_name'] = 'Bob'}.should_not raise_error
    end

    it 'should be able to read/write to an existing property using a method call' do
      @dash.first_name = 'Franklin'
      @dash.first_name.should == 'Franklin'
    end
  end

  describe ' initializing with a Hash' do
    it 'should not be able to initialize non-existent properties' do
      lambda{DashTest.new(:bork => 'abc')}.should raise_error(NoMethodError)
    end

    it 'should set properties that it is able to' do
      DashTest.new(:first_name => 'Michael').first_name.should == 'Michael'
    end
  end

  describe 'initializing with a nil' do
    it 'accepts nil' do
      lambda { DashTest.new(nil) }.should_not raise_error
    end
  end

  describe ' defaults' do
    before do
      @dash = DashTest.new
    end

    it 'should return the default value for defaulted' do
      DashTest.property :defaulted, :default => 'abc'
      DashTest.new.defaulted.should == 'abc'
    end
  end
end

describe Subclassed do
  it "should inherit all properties from DashTest" do
    Subclassed.properties.size.should == 6
  end

  it "should inherit all defaults from DashTest" do
    Subclassed.defaults.size.should == 6
  end

  it "should init without raising" do
    lambda { Subclassed.new }.should_not raise_error
    lambda { Subclassed.new(:first_name => 'Michael') }.should_not raise_error
  end

  it "should share defaults from DashTest" do
    Subclassed.new.count.should == 0
  end
end
