require 'spec_helper'

RSpec.describe Hashie::Extensions::Mash::RequiredKeys do
  context 'when included in a Mash' do
    class RequiredKeysMash < Hashie::Mash
      include Hashie::Extensions::Mash::RequiredKeys

      required_keys :name, :email
    end

    it 'raises an error when a required key is missing' do
      expect do
        RequiredKeysMash.new(email: 'bob@example.com')
      end.to raise_error(ArgumentError, 'The following keys are required: name')
    end

    it 'raises an error listing all missing required keys' do
      expect do
        RequiredKeysMash.new
      end.to raise_error(ArgumentError, 'The following keys are required: name, email')
    end

    it 'does not raise when all required keys are set' do
      expect do
        RequiredKeysMash.new(name: 'Bob', email: 'bob@example.com')
      end.not_to raise_error
    end

    it 'accepts required keys provided as strings' do
      expect do
        RequiredKeysMash.new('name' => 'Bob', 'email' => 'bob@example.com')
      end.not_to raise_error
    end

    it 'still allows arbitrary, undeclared keys to be set' do
      mash = RequiredKeysMash.new(name: 'Bob', email: 'bob@example.com')
      mash.age = 42
      expect(mash.age).to eq(42)
    end

    it 'raises an error when a required key is explicitly set to nil' do
      expect do
        RequiredKeysMash.new(name: 'Bob', email: nil)
      end.to raise_error(ArgumentError, 'The following keys are required: email')
    end
  end

  context 'when subclassed' do
    class BaseRequiredKeysMash < Hashie::Mash
      include Hashie::Extensions::Mash::RequiredKeys

      required_keys :name
    end

    class SubRequiredKeysMash < BaseRequiredKeysMash
      required_keys :email
    end

    it 'inherits required keys from the superclass' do
      expect do
        SubRequiredKeysMash.new(email: 'bob@example.com')
      end.to raise_error(ArgumentError, 'The following keys are required: name')
    end

    it 'combines required keys from the subclass' do
      expect do
        SubRequiredKeysMash.new(name: 'Bob')
      end.to raise_error(ArgumentError, 'The following keys are required: email')
    end

    it 'does not affect the superclass required keys' do
      expect(BaseRequiredKeysMash.required_keys).to eq(['name'])
    end

    it 'does not raise when all required keys are set' do
      expect do
        SubRequiredKeysMash.new(name: 'Bob', email: 'bob@example.com')
      end.not_to raise_error
    end
  end
end
