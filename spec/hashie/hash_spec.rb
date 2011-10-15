require 'spec_helper'

describe Hashie::Hash do
  it "should be convertible to a Hashie::Mash" do
    mash = Hashie::Hash[:some => "hash"].to_mash
    mash.is_a?(Hashie::Mash).should be_true
    mash.some.should == "hash"
  end
  
  it "#stringify_keys! should turn all keys into strings" do
    hash = Hashie::Hash[:a => "hey", 123 => "bob"]
    hash.stringify_keys!
    hash.should == Hashie::Hash["a" => "hey", "123" => "bob"]
  end
  
  it "#stringify_keys should return a hash with stringified keys" do
    hash = Hashie::Hash[:a => "hey", 123 => "bob"]
    stringified_hash = hash.stringify_keys
    hash.should == Hashie::Hash[:a => "hey", 123 => "bob"]
    stringified_hash.should == Hashie::Hash["a" => "hey", "123" => "bob"]
  end

  describe '#to_hash' do
    it 'should convert it to a hash with string keys by default' do
      Hashie::Hash.new.merge(:a => 'hey', :b => 'foo').to_hash.should == {'a' => 'hey', 'b' => 'foo'}
    end

    it 'should convert to a hash with symbol keys if :symbolize_keys is passed in' do
      Hashie::Hash.new.merge('a' => 'hey', 'b' => 'doo').to_hash(:symbolize_keys => true).should == {:a => 'hey', :b => 'doo'}
    end
  end
end
