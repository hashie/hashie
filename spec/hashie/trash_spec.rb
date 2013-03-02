require 'spec_helper'

describe Hashie::Trash do
  class TrashTest < Hashie::Trash
    property :first_name, :from => :firstName
  end

  let(:trash) { TrashTest.new }

  describe 'translating properties' do
    it 'adds the property to the list' do
      TrashTest.properties.should include(:first_name)
    end

    it 'creates a method for reading the property' do
      trash.should respond_to(:first_name)
    end

    it 'creates a method for writing the property' do
      trash.should respond_to(:first_name=)
    end

    it 'creates a method for writing the translated property' do
      trash.should respond_to(:firstName=)
    end

    it 'does not create a method for reading the translated property' do
      trash.should_not respond_to(:firstName)
    end
  end

  describe 'writing to properties' do

    it 'does not write to a non-existent property using []=' do
      lambda{trash['abc'] = 123}.should raise_error(NoMethodError)
    end

    it 'writes to an existing property using []=' do
      lambda{trash['first_name'] = 'Bob'}.should_not raise_error
    end

    it 'writes to a translated property using []=' do
      lambda{trash['firstName'] = 'Bob'}.should_not raise_error
    end

    it 'reads/writes to an existing property using a method call' do
      trash.first_name = 'Franklin'
      trash.first_name.should == 'Franklin'
    end

    it 'writes to an translated property using a method call' do
      trash.firstName = 'Franklin'
      trash.first_name.should == 'Franklin'
    end

    it 'writes to a translated property using #replace' do
      trash.replace(:firstName => 'Franklin')
      trash.first_name.should == 'Franklin'
    end

    it 'writes to a non-translated property using #replace' do
      trash.replace(:first_name => 'Franklin')
      trash.first_name.should == 'Franklin'
    end
  end

  describe ' initializing with a Hash' do
    it 'does not initialize non-existent properties' do
      lambda{TrashTest.new(:bork => 'abc')}.should raise_error(NoMethodError)
    end

    it 'sets the desired properties' do
      TrashTest.new(:first_name => 'Michael').first_name.should == 'Michael'
    end

    context "with both the translated property and the property" do
      it 'sets the desired properties' do
        TrashTest.new(:first_name => 'Michael', :firstName=>'Maeve').first_name.should == 'Michael'
      end
    end

    it 'sets the translated properties' do
      TrashTest.new(:firstName => 'Michael').first_name.should == 'Michael'
    end
  end

  describe 'translating properties using a proc' do
    class TrashLambdaTest < Hashie::Trash
      property :first_name, :from => :firstName, :with => lambda { |value| value.reverse }
    end

    let(:lambda_trash) { TrashLambdaTest.new }

    it 'should translate the value given on initialization with the given lambda' do
      TrashLambdaTest.new(:firstName => 'Michael').first_name.should == 'Michael'.reverse
    end

    it 'should not translate the value if given with the right property' do
      TrashTest.new(:first_name => 'Michael').first_name.should == 'Michael'
    end

    it 'should translate the value given as property with the given lambda' do
      lambda_trash.firstName = 'Michael'
      lambda_trash.first_name.should == 'Michael'.reverse
    end

    it 'should not translate the value given as right property' do
      lambda_trash.first_name = 'Michael'
      lambda_trash.first_name.should == 'Michael'
    end
  end

  describe 'translating properties without from option using a proc' do

    class TrashLambdaTest2 < Hashie::Trash
      property :first_name, :transform_with => lambda { |value| value.reverse }
    end

    let(:lambda_trash) { TrashLambdaTest2.new }

    it 'should translate the value given as property with the given lambda' do
      lambda_trash.first_name = 'Michael'
      lambda_trash.first_name.should == 'Michael'.reverse
    end

    it 'should transform the value when given in constructor' do
      TrashLambdaTest2.new(:first_name => 'Michael').first_name.should == 'Michael'.reverse
    end

    context "when :from option is given" do
      class TrashLambdaTest3 < Hashie::Trash
        property :first_name, :from => :firstName, :transform_with => lambda { |value| value.reverse }
      end

      it 'should not override the :from option in the constructor' do
        TrashLambdaTest3.new(:first_name => 'Michael').first_name.should == 'Michael'
      end

      it 'should not override the :from option when given as property' do
        t = TrashLambdaTest3.new
        t.first_name = 'Michael'
        t.first_name.should == 'Michael'
      end

    end
  end

  it "should raise an error when :from have the same value as property" do
    expect {
      class WrongTrash < Hashie::Trash
        property :first_name, :from => :first_name
      end
    }.to raise_error(ArgumentError)
  end
end
