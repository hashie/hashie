require 'spec_helper'

describe Hashie::MethodHash do

  context "when initialized by a simple hash" do
    subject(:method_hash) { Hashie::MethodHash.new({:name => 'John Smith'}) }
    it "acts like a ::Hash" do
      method_hash[:name].should == 'John Smith'
    end

    it "is accessible by Hashie::MethodAccess" do
      method_hash.name.should == 'John Smith'
    end
  end

  context "when initialized by a nested hash" do
    let(:nested_hash) { {:name => 'John Smith', :address => {:street => '123 test st.', :city => 'Somewhere', :state => 'CA', :zip => '90210'}} }
    subject(:method_hash) { Hashie::MethodHash.new(nested_hash) }

    it "is accessible by Hashie::MethodAccess on all levels of hashing" do
      method_hash.name.should == 'John Smith'
      method_hash.address.city.should == 'Somewhere'
    end
  end

  context "when initialized with a value pointing to an array with hash elements" do
    let(:hash_with_array) { {:name => 'John Smith', :contacts => [{:name => 'Jane Doe', :phone => 1234567890}, {:name => 'Jonny Smith', :phone => 5555555555}]} }
    subject(:method_hash) { Hashie::MethodHash.new(hash_with_array) }

    it "is accessible by Hashie::MethodAccess on all hash values including hash elements in the array" do
      method_hash.name.should == 'John Smith'
      method_hash.contacts.first.name.should == 'Jane Doe'
    end
  end

  context "when initialized with a bloc" do
    subject(:method_hash) { Hashie::MethodHash.new { 'Not Available' } }

    it "honors the default value provided by the block" do
      method_hash.blood_type.should == 'Not Available'
    end
  end

end
