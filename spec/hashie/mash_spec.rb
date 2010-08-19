require 'spec_helper'

describe Hashie::Mash do
  before(:each) do
    @mash = Hashie::Mash.new
  end

  it "should inherit from hash" do
    @mash.is_a?(Hash).should be_true
  end

  it "should be able to set hash values through method= calls" do
    @mash.test = "abc"
    @mash["test"].should == "abc"
  end

  it "should be able to retrieve set values through method calls" do
    @mash["test"] = "abc"
    @mash.test.should == "abc"
  end

  it "should test for already set values when passed a ? method" do
    @mash.test?.should be_false
    @mash.test = "abc"
    @mash.test?.should be_true
  end
  
  it "should return false on a ? method if a value has been set to nil or false" do
    @mash.test = nil
    @mash.should_not be_test
    @mash.test = false
    @mash.should_not be_test
  end

  it "should make all [] and []= into strings for consistency" do
    @mash["abc"] = 123
    @mash.key?('abc').should be_true
    @mash["abc"].should == 123
  end

  it "should have a to_s that is identical to its inspect" do
    @mash.abc = 123
    @mash.to_s.should == @mash.inspect
  end

  it "should return nil instead of raising an error for attribute-esque method calls" do
    @mash.abc.should be_nil
  end

  it "should return a Hashie::Mash when passed a bang method to a non-existenct key" do
    @mash.abc!.is_a?(Hashie::Mash).should be_true
  end

  it "should return the existing value when passed a bang method for an existing key" do
    @mash.name = "Bob"
    @mash.name!.should == "Bob"
  end

  it "#initializing_reader should return a Hashie::Mash when passed a non-existent key" do
    @mash.initializing_reader(:abc).is_a?(Hashie::Mash).should be_true
  end

  it "should allow for multi-level assignment through bang methods" do
    @mash.author!.name = "Michael Bleigh"
    @mash.author.should == Hashie::Mash.new(:name => "Michael Bleigh")
    @mash.author!.website!.url = "http://www.mbleigh.com/"
    @mash.author.website.should == Hashie::Mash.new(:url => "http://www.mbleigh.com/")
  end

  it "#deep_update should recursively Hashie::Mash Hashie::Mashes and hashes together" do
    @mash.first_name = "Michael"
    @mash.last_name = "Bleigh"
    @mash.details = Hashie::Hash[:email => "michael@asf.com"].to_mash
    @mash.deep_update({:details => {:email => "michael@intridea.com"}})
    @mash.details.email.should == "michael@intridea.com"
  end

  it "should convert hash assignments into Hashie::Mashes" do
    @mash.details = {:email => 'randy@asf.com', :address => {:state => 'TX'} }
    @mash.details.email.should == 'randy@asf.com'
    @mash.details.address.state.should == 'TX'
  end

  it "should not convert the type of Hashie::Mashes childs to Hashie::Mash" do
    class MyMash < Hashie::Mash
    end

    record = MyMash.new
    record.son = MyMash.new
    record.son.class.should == MyMash
  end
  
  it "should not change the class of Mashes when converted" do
    class SubMash < Hashie::Mash
    end
    
    record = Hashie::Mash.new
    son = SubMash.new
    record['submash'] = son
    record['submash'].should be_kind_of(SubMash)
  end
  
  describe '#respond_to?' do
    it 'should respond to a normal method' do
      Hashie::Mash.new.should be_respond_to(:key?)
    end
    
    it 'should respond to a set key' do
      Hashie::Mash.new(:abc => 'def').should be_respond_to(:abc)
    end
  end

  context "#initialize" do
    it "should convert an existing hash to a Hashie::Mash" do
      converted = Hashie::Mash.new({:abc => 123, :name => "Bob"})
      converted.abc.should == 123
      converted.name.should == "Bob"
    end

    it "should convert hashes recursively into Hashie::Mashes" do
      converted = Hashie::Mash.new({:a => {:b => 1, :c => {:d => 23}}})
      converted.a.is_a?(Hashie::Mash).should be_true
      converted.a.b.should == 1
      converted.a.c.d.should == 23
    end

    it "should convert hashes in arrays into Hashie::Mashes" do
      converted = Hashie::Mash.new({:a => [{:b => 12}, 23]})
      converted.a.first.b.should == 12
      converted.a.last.should == 23
    end

    it "should convert an existing Hashie::Mash into a Hashie::Mash" do
      initial = Hashie::Mash.new(:name => 'randy', :address => {:state => 'TX'})
      copy = Hashie::Mash.new(initial)
      initial.name.should == copy.name
      initial.object_id.should_not == copy.object_id
      copy.address.state.should == 'TX'
      copy.address.state = 'MI'
      initial.address.state.should == 'TX'
      copy.address.object_id.should_not == initial.address.object_id
    end

    it "should accept a default block" do
      initial = Hashie::Mash.new { |h,i| h[i] = []}
      initial.default_proc.should_not be_nil
      initial.default.should be_nil
      initial.test.should == []
      initial.test?.should be_true
    end

    describe "to_json" do

      it "should render to_json" do
        @mash.foo = :bar
        @mash.bar = {"homer" => "simpson"}
        expected = {"foo" => "bar", "bar" => {"homer" => "simpson"}}
        JSON.parse(@mash.to_json).should == expected
      end
    end
  end
end
