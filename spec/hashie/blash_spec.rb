require 'spec_helper'
require 'delegate'

describe Hashie::Blash do
  before(:each) do
    @blash = Hashie::Blash.new
  end

  it "should inherit from hash" do
    @blash.is_a?(Hash).should be_true
  end

  it "should be able to set hash values through method= calls" do
    @blash.test = "abc"
    @blash["test"].should == "abc"
  end

  it "should be able to retrieve set values through method calls" do
    @blash["test"] = "abc"
    @blash.test.should == "abc"
  end

  it "should error when setting values with weird arguments" do
    expect { @blash.send("test=") }.to raise_error("wrong number of arguments (0 for 1)")
    expect { @blash.send("test=", "way", "too", "many") }.to raise_error("wrong number of arguments (3 for 1)")
  end

  it "should error when retrieving values with arguments" do
    @blash.test = "abc"
    expect { @blash.test(123) }.to raise_error("wrong number of arguments (1 for 0)")
  end

  it "should pass sub-level blash through blocks" do
    expect {|b| @blash.test(&b) }.to yield_with_args(Hashie::Blash)
  end

  it "should allow sub-level assignment with blocks" do
    @blash.test do |t|
      t.foo = "bar"
    end
    @blash.test.foo.should == "bar"
  end

  it "should error when attempting block assigment on non-blash attributes" do
    @blash.test = "abc"
    expect { @blash.test { puts 'yo' } }.to raise_error("key 'test' already contains a String")
  end

  it "should test for already set values when passed a ? method" do
    @blash.test?.should be_false
    @blash.test = "abc"
    @blash.test?.should be_true
  end

  it "should return false on a ? method if a value has been set to nil or false" do
    @blash.test = nil
    @blash.should_not be_test
    @blash.test = false
    @blash.should_not be_test
  end

  it "should error when passing arguments to a ? method" do
    expect { @blash.test? 123 }.to raise_error("wrong number of arguments (1 for 0)")
  end

  it "should make all [] and []= into strings for consistency" do
    @blash[:abc] = 123
    @blash.key?('abc').should be_true
    @blash["abc"].should == 123
  end

  it "should have a to_s that is identical to its inspect" do
    @blash.abc = 123
    @blash.to_s.should == @blash.inspect
  end

  it "should return nil instead of raising an error for attribute-esque method calls" do
    @blash.abc.should be_nil
  end

  it "#initializing_reader should return a Hashie::Blash when passed a non-existent key" do
    @blash.initializing_reader(:abc).is_a?(Hashie::Blash).should be_true
  end

  it "should not call super if id is not a key" do
    @blash.id.should == nil
  end

  it "should return the value if id is a key" do
    @blash.id = "Steve"
    @blash.id.should == "Steve"
  end

  it "should not call super if type is not a key" do
    @blash.type.should == nil
  end

  it "should return the value if type is a key" do
    @blash.type = "Steve"
    @blash.type.should == "Steve"
  end

  it "should work with Hash#default" do
    @blash.default = "foobar"
    @blash.doesnt_exist.should == "foobar"
  end

  it "should not respond to underscore or bang methods" do
    expect { @blash.test!.explode }.to raise_error(NoMethodError)
    expect { @blash.test_.explode }.to raise_error(NoMethodError)
  end

  context "updating" do
    subject {
      described_class.new :first_name => "Michael", :last_name => "Bleigh",
        :details => {:email => "michael@asf.com", :address => "Nowhere road"}
    }

    describe "#deep_update" do
      it "should recursively Hashie::Blash Hashie::Blashes and hashes together" do
        subject.deep_update(:details => {:email => "michael@intridea.com", :city => "Imagineton"})
        subject.first_name.should == "Michael"
        subject.details.email.should == "michael@intridea.com"
        subject.details.address.should == "Nowhere road"
        subject.details.city.should == "Imagineton"
      end

      it "should make #update deep by default" do
        subject.update(:details => {:address => "Fake street"}).should eql(subject)
        subject.details.address.should == "Fake street"
        subject.details.email.should == "michael@asf.com"
      end

      it "should clone before a #deep_merge" do
        duped = subject.deep_merge(:details => {:address => "Fake street"})
        duped.should_not eql(subject)
        duped.details.address.should == "Fake street"
        subject.details.address.should == "Nowhere road"
        duped.details.email.should == "michael@asf.com"
      end

      it "regular #merge should be deep" do
        duped = subject.merge(:details => {:email => "michael@intridea.com"})
        duped.should_not eql(subject)
        duped.details.email.should == "michael@intridea.com"
        duped.details.address.should == "Nowhere road"
      end

      # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-update
      it "accepts a block" do
        duped = subject.merge(:details => {:address => "Pasadena CA"}) {|key, oldv, newv| [oldv, newv].join(', ')}
        duped.details.address.should == 'Nowhere road, Pasadena CA'
      end
    end

    describe "shallow update" do
      it "should shallowly Hashie::Blash Hashie::Blashes and hashes together" do
        subject.shallow_update(:details => {
          :email => "michael@intridea.com", :city => "Imagineton"
        }).should eql(subject)

        subject.first_name.should == "Michael"
        subject.details.email.should == "michael@intridea.com"
        subject.details.address.should be_nil
        subject.details.city.should == "Imagineton"
      end

      it "should clone before a #regular_merge" do
        duped = subject.shallow_merge(:details => {:address => "Fake street"})
        duped.should_not eql(subject)
      end

      it "regular merge should be shallow" do
        duped = subject.shallow_merge(:details => {:address => "Fake street"})
        duped.details.address.should == "Fake street"
        subject.details.address.should == "Nowhere road"
        duped.details.email.should be_nil
      end
    end

    describe '#replace' do
      before do
        subject.replace(:middle_name => "Cain",
          :details => {:city => "Imagination"})
      end

      it 'return self' do
        subject.replace(:foo => "bar").to_hash.should == {"foo" => "bar"}
      end

      it 'sets all specified keys to their corresponding values' do
        subject.middle_name?.should be_true
        subject.details?.should be_true
        subject.middle_name.should == "Cain"
        subject.details.city?.should be_true
        subject.details.city.should == "Imagination"
      end

      it 'leaves only specified keys' do
        subject.keys.sort.should == ['details', 'middle_name']
        subject.first_name?.should be_false
        subject.should_not respond_to(:first_name)
        subject.last_name?.should be_false
        subject.should_not respond_to(:last_name)
      end
    end

    describe 'delete' do
      it 'should delete with String key' do
        subject.delete('details')
        subject.details.should be_nil
        subject.should_not be_respond_to :details
      end

      it 'should delete with Symbol key' do
        subject.delete(:details)
        subject.details.should be_nil
        subject.should_not be_respond_to :details
      end
    end
  end

  it "should convert hash assignments into Hashie::Blashes" do
    @blash.details = {:email => 'randy@asf.com', :address => {:state => 'TX'} }
    @blash.details.email.should == 'randy@asf.com'
    @blash.details.address.state.should == 'TX'
  end

  it "should not convert the type of Hashie::Blashes childs to Hashie::Blash" do
    class MyBlash < Hashie::Blash
    end

    record = MyBlash.new
    record.son = MyBlash.new
    record.son.class.should == MyBlash
  end

  it "should not change the class of Blashes when converted" do
    class SubBlash < Hashie::Blash
    end

    record = Hashie::Blash.new
    son = SubBlash.new
    record['subblash'] = son
    record['subblash'].should be_kind_of(SubBlash)
  end

  it "should respect the class when converting the value" do
    record = Hashie::Blash.new
    record.details = Hashie::Blash.new({:email => "randy@asf.com"})
    record.details.should be_kind_of(Hashie::Blash)
  end

  it "should respect another subclass when converting the value" do
    record = Hashie::Blash.new

    class SubBlash < Hashie::Blash
    end

    son = SubBlash.new({:email => "foo@bar.com"})
    record.details = son
    record.details.should be_kind_of(SubBlash)
  end

  describe "#respond_to?" do
    it 'should respond to a normal method' do
      Hashie::Blash.new.should be_respond_to(:key?)
    end

    it 'should respond to a set key' do
      Hashie::Blash.new(:abc => 'def').should be_respond_to(:abc)
    end

    it 'should respond to a set key with a suffix' do
      %w(= ?).each do |suffix|
        Hashie::Blash.new(:abc => 'def').should be_respond_to(:"abc#{suffix}")
      end
    end

    it 'should respond to an unknown key with a suffix' do
      %w(= ?).each do |suffix|
        Hashie::Blash.new(:abc => 'def').should be_respond_to(:"xyz#{suffix}")
      end
    end

    it 'should not respond to an unknown suffix' do
      %w(_ !).each do |suffix|
        Hashie::Blash.new(:abc => 'def').should_not be_respond_to(:"xyz#{suffix}")
      end
    end

    it "should not respond to an unknown key without a suffix" do
      Hashie::Blash.new(:abc => 'def').should_not be_respond_to(:xyz)
    end
  end

  context "#initialize" do
    it "should convert an existing hash to a Hashie::Blash" do
      converted = Hashie::Blash.new({:abc => 123, :name => "Bob"})
      converted.abc.should == 123
      converted.name.should == "Bob"
    end

    it "should convert hashes recursively into Hashie::Blashes" do
      converted = Hashie::Blash.new({:a => {:b => 1, :c => {:d => 23}}})
      converted.a.is_a?(Hashie::Blash).should be_true
      converted.a.b.should == 1
      converted.a.c.d.should == 23
    end

    it "should convert hashes in arrays into Hashie::Blashes" do
      converted = Hashie::Blash.new({:a => [{:b => 12}, 23]})
      converted.a.first.b.should == 12
      converted.a.last.should == 23
    end

    it "should convert an existing Hashie::Blash into a Hashie::Blash" do
      initial = Hashie::Blash.new(:name => 'randy', :address => {:state => 'TX'})
      copy = Hashie::Blash.new(initial)
      initial.name.should == copy.name
      initial.__id__.should_not == copy.__id__
      copy.address.state.should == 'TX'
      copy.address.state = 'MI'
      initial.address.state.should == 'TX'
      copy.address.__id__.should_not == initial.address.__id__
    end

    it "should accept a default block" do
      initial = Hashie::Blash.new { |h,i| h[i] = []}
      initial.default_proc.should_not be_nil
      initial.default.should be_nil
      initial.test.should == []
      initial.test?.should be_true
    end

    it "should convert Hashie::Blashes within Arrays back to Hashes" do
      initial_hash = {"a" => [{"b" => 12, "c" =>["d" => 50, "e" => 51]}, 23]}
      converted = Hashie::Blash.new(initial_hash)
      converted.to_hash["a"].first.is_a?(Hashie::Blash).should be_false
      converted.to_hash["a"].first.is_a?(Hash).should be_true
      converted.to_hash["a"].first["c"].first.is_a?(Hashie::Blash).should be_false
      converted.to_hash({:symbolize_keys => true}).keys[0].should == :a
    end
  end

  describe "#fetch" do
    let(:hash) { {:one => 1, :other => false} }
    let(:blash) { Hashie::Blash.new(hash) }

    context "when key exists" do
      it "returns the value" do
        blash.fetch(:one).should eql(1)
      end

      it "returns the value even if the value is falsy" do
        blash.fetch(:other).should eql(false)
      end

      context "when key has other than original but acceptable type" do
        it "returns the value" do
          blash.fetch('one').should eql(1)
        end
      end
    end

    context "when key does not exist" do
      it "should raise KeyError" do
        error = RUBY_VERSION =~ /1.8/ ? IndexError : KeyError
        expect { blash.fetch(:two) }.to raise_error(error)
      end

      context "with default value given" do
        it "returns default value" do
          blash.fetch(:two, 8).should eql(8)
        end

        it "returns default value even if it is falsy" do
          blash.fetch(:two, false).should eql(false)
        end
      end

      context "with block given" do
        it "returns default value" do
          blash.fetch(:two) {|key|
            "block default value"
          }.should eql("block default value")
        end
      end
    end
  end
end
