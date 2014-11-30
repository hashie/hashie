require 'spec_helper'
require 'support/module_context'

describe Hashie::Extensions::SymbolizeKeys do
  include_context 'included hash module'

  describe '#symbolize_keys!' do
    it 'converts keys to symbols' do
      subject['abc'] = 'abc'
      subject['def'] = 'def'
      subject.symbolize_keys!
      expect((subject.keys & [:abc, :def]).size).to eq 2
    end

    it 'converts nested instances of the same class' do
      subject['ab'] = dummy_class.new
      subject['ab']['cd'] = dummy_class.new
      subject['ab']['cd']['ef'] = 'abcdef'
      subject.symbolize_keys!
      expect(subject).to eq(ab: { cd: { ef: 'abcdef' } })
    end

    it 'converts nested hashes' do
      subject['ab'] = { 'cd' => { 'ef' => 'abcdef' } }
      subject.symbolize_keys!
      expect(subject).to eq(ab: { cd: { ef: 'abcdef' } })
    end

    it 'performs deep conversion within nested arrays' do
      subject['ab'] = []
      subject['ab'] << dummy_class.new
      subject['ab'] << dummy_class.new
      subject['ab'][0]['cd'] = 'abcd'
      subject['ab'][1]['ef'] = 'abef'
      subject.symbolize_keys!
      expect(subject).to eq(ab: [{ cd: 'abcd' }, { ef: 'abef' }])
    end

    it 'returns itself' do
      expect(subject.symbolize_keys!).to eq subject
    end
  end

  describe '#symbolize_keys' do
    it 'converts keys to symbols' do
      subject['abc'] = 'def'
      copy = subject.symbolize_keys
      expect(copy[:abc]).to eq 'def'
    end

    it 'does not alter the original' do
      subject['abc'] = 'def'
      copy = subject.symbolize_keys
      expect(subject.keys).to eq ['abc']
      expect(copy.keys).to eq [:abc]
    end
  end
end
