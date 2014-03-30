require 'spec_helper'

describe Hashie::Trash do

  let :trash_class do
    Class.new(described_class) { property :first_name, :from => :firstName }
  end

  let(:value) { {} }
  subject { trash_class.new(value) }

  describe 'translating properties' do
    it 'adds the property to the list' do
      trash_class.properties.should include(:first_name)
    end

    it 'creates a method for reading the property' do
      subject.should respond_to(:first_name)
    end

    it 'creates a method for writing the property' do
      subject.should respond_to(:first_name=)
    end

    it 'creates a method for writing the translated property' do
      subject.should respond_to(:firstName=)
    end

    it 'does not create a method for reading the translated property' do
      subject.should_not respond_to(:firstName)
    end

    context 'multiple properties' do
      let :trash_class do
        Class.new(described_class) do
          property :first_name, :from => :firstName
          property :last_name,  :from => :firstName
        end
      end

      let(:value) { { :firstName => 'Michael' } }

      it 'translates all properties' do
        subject.keys.should =~ %w{first_name last_name}
      end

      it 'assigns all values' do
        subject.first_name.should == 'Michael'
        subject.last_name.should  == 'Michael'
      end
    end
  end

  describe 'writing to properties' do
    it 'does not write to a non-existent property using []=' do
      lambda{subject['abc'] = 123}.should raise_error(NoMethodError)
    end

    it 'writes to an existing property using []=' do
      lambda{subject['first_name'] = 'Bob'}.should_not raise_error
    end

    it 'writes to a translated property using []=' do
      lambda{subject['firstName'] = 'Bob'}.should_not raise_error
    end

    it 'reads/writes to an existing property using a method call' do
      subject.first_name = 'Franklin'
      subject.first_name.should == 'Franklin'
    end

    it 'writes to an translated property using a method call' do
      subject.firstName = 'Franklin'
      subject.first_name.should == 'Franklin'
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

  describe 'initializing with a Hash' do
    it 'does not initialize non-existent properties' do
      lambda{trash_class.new(:bork => 'abc')}.should raise_error(NoMethodError)
    end

    it 'sets the desired properties' do
      trash_class.new(:first_name => 'Michael').first_name.should == 'Michael'
    end

    context "with both the translated property and the property" do
      it 'sets the desired properties' do
        trash_class.new(:first_name => 'Michael', :firstName=>'Maeve').first_name.should == 'Michael'
      end
    end

    it 'sets the translated properties' do
      trash_class.new(:firstName => 'Michael').first_name.should == 'Michael'
    end
  end

  describe 'translating properties using a proc' do
    let :trash_class do
      Class.new(described_class) do
        property :first_name, :from => :firstName, :with => lambda { |value| value.reverse }
      end
    end

    context 'on initialization' do
      let(:value) { {:firstName => 'Michael'} }

      it 'translates the value given with the given lambda' do
        subject.first_name.should == 'Michael'.reverse
      end

      context 'given with the right property' do
        let(:value) { {:first_name => 'Michael'} }

        it 'does not translate the value' do
          subject.first_name.should == 'Michael'
        end
      end
    end

    context 'on setter call' do
      context "the value given as property" do
        before { subject.firstName = 'Michael' }

        it 'translates with the given lambda' do
          subject.first_name.should == 'Michael'.reverse
        end
      end

      context "the value given as right property" do
        before { subject.first_name = 'Michael' }

        it 'does not translate' do
          subject.first_name.should == 'Michael'
        end
      end
    end
  end

  describe 'translating properties without from option using a proc' do
    let :trash_class do
      Class.new(described_class) do
        property :first_name, :transform_with => lambda { |value| value.reverse }
      end
    end

    it 'translates the value given as property with the given lambda' do
      subject.first_name = 'Michael'
      subject.first_name.should == 'Michael'.reverse
    end

    it 'transforms the value when given in constructor' do
      trash_class.new(:first_name => 'Michael').first_name.should == 'Michael'.reverse
    end

    context "when :from option is given" do
      let :trash_class do
        Class.new(described_class) do
          property :first_name, :from => :firstName, :transform_with => lambda { |value| value.reverse }
        end
      end

      it 'does not override the :from option in the constructor' do
        trash_class.new(:first_name => 'Michael').first_name.should == 'Michael'
      end

      it 'does not override the :from option when given as property' do
        subject.first_name = 'Michael'
        subject.first_name.should == 'Michael'
      end

      context 'multiple properties' do
        let :trash_class do
          Class.new(described_class) do
            property :first_name, :from => :firstName, :with => lambda { |value| value.reverse }
            property :last_name,  :from => :firstName, :with => lambda { |value| value.upcase }
          end
        end

        let(:value) { { :firstName => 'Michael' } }

        it 'translates all properties' do
          subject.keys.should =~ %w{first_name last_name}
        end

        it 'assigns all values' do
          subject.first_name.should == 'leahciM'
          subject.last_name.should  == 'MICHAEL'
        end
      end
    end

    context 'multiple properties' do
      class MultiplePropertiesProcTest < Hashie::Trash
        property :first_name, :from => :firstName, :with => lambda { |value| value.reverse }
        property :last_name,  :from => :firstName, :with => lambda { |value| value.upcase }
      end

      let(:trash) { MultiplePropertiesProcTest.new(:firstName => 'Michael') }

      it 'translates all properties' do
        trash.keys.should =~ %w{first_name last_name}
      end

      it 'assigns all values' do
        trash.first_name.should == 'leahciM'
        trash.last_name.should  == 'MICHAEL'
      end
    end
  end

  context ":from have the same value as property" do
    it "raises an error" do
      expect {
        Class.new(described_class) { property :first_name, :from => :first_name }
      }.to raise_error(ArgumentError)
    end
  end
end
