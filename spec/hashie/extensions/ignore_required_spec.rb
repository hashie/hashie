require 'spec_helper'

describe Hashie::Extensions::IgnoreRequired do
  context 'included in Dash' do
    class ForgivingDash < Hashie::Dash
      include Hashie::Extensions::IgnoreRequired
      property :city,     required: true
      property :state,    required: true, from: :province
      property :zip,      required: true
    end

    subject { ForgivingDash }

    it 'silently ignores required properties on initialization' do
      expect { subject.new(city: 'New York') }.to_not raise_error
    end

    it 'raises errors for undefined properties on initialization' do
      expect { subject.new(city: 'Toronto', province: 'Ontario') }.to raise_error(NoMethodError, /property 'province' is not defined/)
    end

    it 'requires properties to be declared on assignment' do
      hash = subject.new(city: 'Toronto')
      expect { hash.country = 'Canada' }.to raise_error(NoMethodError)
    end

    it 'requires properties to be declared on access' do
      hash = subject.new(city: 'Toronto')
      expect { hash.country }.to raise_error(NoMethodError)
    end
  end

  context 'combined with Coercion' do
    class ForgivingDashWithCoercion < ForgivingDash
      include Hashie::Extensions::Coercion
      coerce_key :zip, ->(v) { format('%05d', v) }
    end

    subject { ForgivingDashWithCoercion }

    it 'works with coerced properties' do
      expect(subject.new(zip: 501).zip).to eq('00501')
    end

    context 'with nested, coerced Dashes' do
      class Address < Hashie::Dash
        property :number, required: true
        property :street, required: true
        property :apartment
      end

      class ForgivingDashWithAddress < ForgivingDashWithCoercion
        property :address, required: true
        coerce_key :address, Address
      end

      subject { ForgivingDashWithAddress }

      it 'does not work propagate to nested, coercable properties' do
        address = { street: 'Pennsylvania Avenue' }
        expect { subject.new(address: address) }.to raise_error(ArgumentError, /property 'number' is required for Address/)
      end
    end
  end
end
