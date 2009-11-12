require File.dirname(__FILE__) + '/../spec_helper'

class DashTest < Hashie::Dash
  property :first_name
  property :email
  property :count, :default => 0
end

describe Hashie::Dash do
  it 'should be a subclass of Hashie::Hash' do
    (Hashie::Dash < Hash).should be_true
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