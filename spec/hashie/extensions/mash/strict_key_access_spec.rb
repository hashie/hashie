require 'spec_helper'

describe Hashie::Extensions::Mash::StrictKeyAccess do
  class StrictMash < Hashie::Mash
    include Hashie::Extensions::Mash::StrictKeyAccess
  end

  it 'fails to be included in a non-Mash' do
    expect do
      Class.new(Hash) { include Hashie::Extensions::Mash::StrictKeyAccess }
    end.to raise_error(ArgumentError, /is not a kind of Hashie::Mash/)
  end

  let(:mash) { StrictMash.new(name: 'Bob', address: { city: 'Springfield' }) }

  context '#method_missing' do
    it 'returns the value for a set key' do
      expect(mash.name).to eq('Bob')
    end

    it 'raises a KeyError for an unset key' do
      expect { mash.age }.to raise_error(KeyError, 'key not found: "age"')
    end

    it 'raises a KeyError for a nested unset key' do
      expect { mash.address.zipcode }.to raise_error(KeyError, 'key not found: "zipcode"')
    end

    it 'preserves nested Mashes as instances of the same class' do
      expect(mash.address).to be_a(StrictMash)
    end

    context 'suffixed methods' do
      it 'supports the truthy suffix for a set key' do
        expect(mash.name?).to eq(true)
      end

      it 'supports the truthy suffix for an unset key without raising' do
        expect(mash.age?).to eq(false)
      end

      it 'supports the assignment suffix for a new key' do
        mash.age = 42
        expect(mash.age).to eq(42)
      end

      it 'supports the bang suffix for an unset key without raising' do
        expect(mash.phone!).to be_a(StrictMash)
        expect(mash.phone).to eq(StrictMash.new)
      end

      it 'supports the underbang suffix for an unset key without raising' do
        expect(mash.phone_).to be_a(StrictMash)
        expect(mash.key?('phone')).to eq(false)
      end
    end
  end

  context '#respond_to?' do
    it 'is true for a set key' do
      expect(mash.respond_to?(:name)).to eq(true)
    end

    it 'is false for an unset key' do
      expect(mash.respond_to?(:age)).to eq(false)
    end

    it 'is true for a suffixed method of an unset key' do
      expect(mash.respond_to?(:age?)).to eq(true)
      expect(mash.respond_to?(:age!)).to eq(true)
      expect(mash.respond_to?(:age_)).to eq(true)
      expect(mash.respond_to?(:age=)).to eq(true)
    end
  end
end
