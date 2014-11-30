require 'spec_helper'
require 'support/module_context'

describe Hashie::Extensions::StringifyKeys do
  include_context 'included hash module'

  describe '#stringify_keys!' do
    it 'converts keys to strings' do
      subject[:abc] = 'abc'
      subject[123] = '123'
      subject.stringify_keys!
      expect((subject.keys & %w(abc 123)).size).to eq 2
    end

    it 'converts nested instances of the same class' do
      subject[:ab] = dummy_class.new
      subject[:ab][:cd] = dummy_class.new
      subject[:ab][:cd][:ef] = 'abcdef'
      subject.stringify_keys!
      expect(subject).to eq('ab' => { 'cd' => { 'ef' => 'abcdef' } })
    end

    it 'converts nested hashes' do
      subject[:ab] = { cd: { ef: 'abcdef' } }
      subject.stringify_keys!
      expect(subject).to eq('ab' => { 'cd' => { 'ef' => 'abcdef' } })
    end

    it 'converts nested arrays' do
      subject[:ab] = []
      subject[:ab] << dummy_class.new
      subject[:ab] << dummy_class.new
      subject[:ab][0][:cd] = 'abcd'
      subject[:ab][1][:ef] = 'abef'
      subject.stringify_keys!
      expect(subject).to eq('ab' => [{ 'cd' => 'abcd' }, { 'ef' => 'abef' }])
    end

    it 'returns itself' do
      expect(subject.stringify_keys!).to eq subject
    end
  end

  describe '#stringify_keys' do
    it 'converts keys to strings' do
      subject[:abc] = 'def'
      copy = subject.stringify_keys
      expect(copy['abc']).to eq 'def'
    end

    it 'does not alter the original' do
      subject[:abc] = 'def'
      copy = subject.stringify_keys
      expect(subject.keys).to eq [:abc]
      expect(copy.keys).to eq %w(abc)
    end
  end
end
