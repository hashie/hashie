require 'spec_helper'

describe Array do
  with_minimum_ruby('2.3.0') do
    describe '#dig' do
      let(:array) { Hashie::Array.new([:a, :b, :c]) }

      it 'works with a string index' do
        expect(array.dig('0')).to eq(:a)
      end

      it 'works with a numeric index' do
        expect(array.dig(1)).to eq(:b)
      end
    end
  end
end
