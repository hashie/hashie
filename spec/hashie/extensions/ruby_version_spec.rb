require 'spec_helper'

RSpec.describe Hashie::Extensions::RubyVersion do
  describe '#<=>' do
    it 'considers identical versions equal' do
      lhs = described_class.new('2.6.0')
      rhs = described_class.new('2.6.0')

      expect(lhs <=> rhs).to eq(0)
      expect(lhs).to eq(rhs)
    end

    it 'considers a lower version less than a higher version' do
      lhs = described_class.new('2.5.0')
      rhs = described_class.new('2.6.0')

      expect(lhs <=> rhs).to eq(-1)
      expect(lhs).to be < rhs
    end

    it 'considers a higher version greater than a lower version' do
      lhs = described_class.new('2.7.0')
      rhs = described_class.new('2.6.0')

      expect(lhs <=> rhs).to eq(1)
      expect(lhs).to be > rhs
    end

    it 'treats a string segment as less than a numeric segment' do
      lhs = described_class.new('2.6.0.alpha')
      rhs = described_class.new('2.6.0.1')

      expect(lhs <=> rhs).to eq(-1)
    end

    it 'treats a numeric segment as greater than a string segment' do
      lhs = described_class.new('2.6.0.1')
      rhs = described_class.new('2.6.0.alpha')

      expect(lhs <=> rhs).to eq(1)
    end
  end
end
