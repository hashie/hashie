require 'spec_helper'

describe Hashie::Extensions::KernelCoercion do
  class StrictCoercableHash < Hash
    include Hashie::Extensions::Coercion
    extend Hashie::Extensions::KernelCoercion

    coerce_key :integer, Integer
    coerce_key :float, Float
    coerce_key :complex, Complex
    coerce_key :rational, Rational
    coerce_key :string, String
    coerce_key :symbol, Symbol
  end

  subject { StrictCoercableHash.new }

  context 'valid values' do
    it 'coerces to Integer' do
      subject[:integer] = '5'
      expect(subject[:integer]).to eq(5)
    end

    it 'coerces to Float' do
      subject[:float] = '5.5'
      expect(subject[:float]).to eq(5.5)
    end

    it 'coerces to Complex' do
      subject[:complex] = '1+2i'
      expect(subject[:complex]).to eq(Complex(1, 2))
    end

    it 'coerces to Rational' do
      subject[:rational] = '1/2'
      expect(subject[:rational]).to eq(Rational(1, 2))
    end

    it 'coerces to String' do
      subject[:string] = 5
      expect(subject[:string]).to eq('5')
    end

    it 'coerces to Symbol using the default, lenient behavior' do
      subject[:symbol] = 'abc'
      expect(subject[:symbol]).to eq(:abc)
    end

    it 'does not coerce values that are already the target type' do
      subject[:integer] = 5
      expect(subject[:integer]).to eq(5)
    end
  end

  context 'invalid values' do
    it 'raises a CoercionError instead of leniently coercing an invalid Integer' do
      expect { subject[:integer] = 'abcd' }
        .to raise_error(Hashie::CoercionError, /invalid value for Integer/)
    end

    it 'raises a CoercionError instead of leniently coercing an invalid Float' do
      expect { subject[:float] = 'abcd' }
        .to raise_error(Hashie::CoercionError, /invalid value for Float/)
    end
  end
end
