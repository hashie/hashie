require 'spec_helper'

RSpec.describe Hashie::Extensions::Mash::SymbolizeKeys do
  it 'raises an error when included in a class that is not a Mash' do
    expect do
      Class.new do
        include Hashie::Extensions::Mash::SymbolizeKeys
      end
    end.to raise_error(ArgumentError)
  end

  context 'when included in a Mash' do
    class SymbolizedMash < Hashie::Mash
      include Hashie::Extensions::Mash::SymbolizeKeys
    end

    it 'symbolizes string keys in the Mash' do
      my_mash = SymbolizedMash.new('test' => 'value')
      expect(my_mash.to_h).to eq(test: 'value')
    end

    it 'preserves keys which cannot be symbolized' do
      my_mash = SymbolizedMash.new(
        '1' => 'symbolizable one',
        1 => 'one',
        [1, 2, 3] => 'testing',
        { 'test' => 'value' } => 'value'
      )
      expect(my_mash.to_h).to eq(
        :'1' => 'symbolizable one',
        1 => 'one',
        [1, 2, 3] => 'testing',
        { 'test' => 'value' } => 'value'
      )
    end
  end

  context 'implicit to_hash on double splat' do
    let(:destructure) { ->(**opts) { opts } }
    let(:my_mash) do
      Class.new(Hashie::Mash) do
        include Hashie::Extensions::Mash::SymbolizeKeys
      end
    end
    let(:instance) { my_mash.new('outer' => { 'inner' => 42 }, 'testing' => [1, 2, 3]) }

    subject { destructure.call(**instance) }

    it 'is converted on method calls' do
      expect(subject).to eq(outer: { inner: 42 }, testing: [1, 2, 3])
    end

    it 'is converted on explicit operator call' do
      expect(**instance).to eq(outer: { inner: 42 }, testing: [1, 2, 3])
    end
  end
end
