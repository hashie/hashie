require 'spec_helper'

describe Hashie::Trash do
  class TrashTest < Hashie::Trash
    property :first_name, from: :firstName
  end

  let(:trash) { TrashTest.new }

  describe 'translating properties' do
    it 'adds the property to the list' do
      expect(TrashTest.properties).to include(:first_name)
    end

    it 'creates a method for reading the property' do
      expect(trash).to respond_to(:first_name)
    end

    it 'creates a method for writing the property' do
      expect(trash).to respond_to(:first_name=)
    end

    it 'creates a method for writing the translated property' do
      expect(trash).to respond_to(:firstName=)
    end

    it 'does not create a method for reading the translated property' do
      expect(trash).not_to respond_to(:firstName)
    end

    it 'maintains translations hash mapping from the original to the translated name' do
      expect(TrashTest.translations[:firstName]).to eq :first_name
    end

    it 'maintains inverse translations hash mapping from the translated to the original name' do
      expect(TrashTest.inverse_translations[:first_name]).to eq :firstName
    end

    it '#permitted_input_keys contain the :from key of properties with translations' do
      expect(TrashTest.permitted_input_keys).to include :firstName
    end
  end

  describe 'standard properties' do
    class TrashTestPermitted < Hashie::Trash
      property :id
    end

    it '#permitted_input_keys contain names of properties without translations' do
      expect(TrashTestPermitted.permitted_input_keys).to include :id
    end
  end

  describe 'writing to properties' do
    it 'does not write to a non-existent property using []=' do
      expect { trash['abc'] = 123 }.to raise_error(NoMethodError)
    end

    it 'writes to an existing property using []=' do
      expect { trash['first_name'] = 'Bob' }.not_to raise_error
    end

    it 'writes to a translated property using []=' do
      expect { trash['firstName'] = 'Bob' }.not_to raise_error
    end

    it 'reads/writes to an existing property using a method call' do
      trash.first_name = 'Franklin'
      expect(trash.first_name).to eq 'Franklin'
    end

    it 'writes to an translated property using a method call' do
      trash.firstName = 'Franklin'
      expect(trash.first_name).to eq 'Franklin'
    end

    it 'writes to a translated property using #replace' do
      trash.replace(firstName: 'Franklin')
      expect(trash.first_name).to eq 'Franklin'
    end

    it 'writes to a non-translated property using #replace' do
      trash.replace(first_name: 'Franklin')
      expect(trash.first_name).to eq 'Franklin'
    end
  end

  describe ' initializing with a Hash' do
    it 'does not initialize non-existent properties' do
      expect { TrashTest.new(bork: 'abc') }.to raise_error(NoMethodError)
    end

    it 'sets the desired properties' do
      expect(TrashTest.new(first_name: 'Michael').first_name).to eq 'Michael'
    end

    context 'with both the translated property and the property' do
      it 'sets the desired properties' do
        expect(TrashTest.new(first_name: 'Michael', firstName: 'Maeve').first_name).to eq 'Michael'
      end
    end

    it 'sets the translated properties' do
      expect(TrashTest.new(firstName: 'Michael').first_name).to eq 'Michael'
    end
  end

  describe 'translating properties using a proc' do
    class TrashLambdaTest < Hashie::Trash
      property :first_name, from: :firstName, with: lambda { |value| value.reverse }
    end

    let(:lambda_trash) { TrashLambdaTest.new }

    it 'translates the value given on initialization with the given lambda' do
      expect(TrashLambdaTest.new(firstName: 'Michael').first_name).to eq 'Michael'.reverse
    end

    it 'does not translate the value if given with the right property' do
      expect(TrashTest.new(first_name: 'Michael').first_name).to eq 'Michael'
    end

    it 'translates the value given as property with the given lambda' do
      lambda_trash.firstName = 'Michael'
      expect(lambda_trash.first_name).to eq 'Michael'.reverse
    end

    it 'does not translate the value given as right property' do
      lambda_trash.first_name = 'Michael'
      expect(lambda_trash.first_name).to eq 'Michael'
    end
  end

  describe 'uses with or transform_with interchangeably' do
    class TrashLambdaTestTransformWith < Hashie::Trash
      property :first_name, from: :firstName, transform_with: lambda { |value| value.reverse }
    end

    let(:lambda_trash) { TrashLambdaTestTransformWith.new }

    it 'translates the value given as property with the given lambda' do
      lambda_trash.firstName = 'Michael'
      expect(lambda_trash.first_name).to eq 'Michael'.reverse
    end

    it 'does not translate the value given as right property' do
      lambda_trash.first_name = 'Michael'
      expect(lambda_trash.first_name).to eq 'Michael'
    end
  end

  describe 'translating properties without from option using a proc' do
    class TrashLambdaTestWithProperties < Hashie::Trash
      property :first_name, transform_with: lambda { |value| value.reverse }
    end

    let(:lambda_trash) { TrashLambdaTestWithProperties.new }

    it 'translates the value given as property with the given lambda' do
      lambda_trash.first_name = 'Michael'
      expect(lambda_trash.first_name).to eq 'Michael'.reverse
    end

    it 'transforms the value when given in constructor' do
      expect(TrashLambdaTestWithProperties.new(first_name: 'Michael').first_name).to eq 'Michael'.reverse
    end

    context 'when :from option is given' do
      class TrashLambdaTest3 < Hashie::Trash
        property :first_name, from: :firstName, transform_with: lambda { |value| value.reverse }
      end

      it 'does not override the :from option in the constructor' do
        expect(TrashLambdaTest3.new(first_name: 'Michael').first_name).to eq 'Michael'
      end

      it 'does not override the :from option when given as property' do
        t = TrashLambdaTest3.new
        t.first_name = 'Michael'
        expect(t.first_name).to eq 'Michael'
      end

    end
  end

  it 'raises an error when :from have the same value as property' do
    expect do
      class WrongTrash < Hashie::Trash
        property :first_name, from: :first_name
      end
    end.to raise_error(ArgumentError)
  end
end
