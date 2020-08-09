# frozen_string_literal: true

require 'spec_helper'

describe Hashie::Extensions::DeepGrep do
  subject { Class.new(Hash) { include Hashie::Extensions::DeepGrep } }
  let(:hash) do
    {
      library: {
        books: [
          { title: 'Call of the Wild' },
          { title: 'Moby Dick' }
        ],
        authors: ['Herman Melville', 'Jack London'],
        shelves: nil,
        location: {
          address: '123 Library St.',
          title: 'Main Library'
        }
      }
    }
  end
  let(:instance) { subject.new.update(hash) }

  describe '#grep' do
    it 'greps a key from a nested hash' do
      expect(instance.deep_grep(/^t/)).to eq([
                                               { title: 'Call of the Wild' },
                                               { title: 'Moby Dick' },
                                               { address: '123 Library St.', title: 'Main Library' }
                                             ])
    end

    it 'greps a value from a nested hash' do
      expect(instance.deep_grep(/^M/)).to eq([
                                               { title: 'Moby Dick' },
                                               { address: '123 Library St.', title: 'Main Library' }
                                             ])
    end

    it 'greps from an array' do
      expect(instance.deep_grep(/Jack/)).to eq([['Herman Melville', 'Jack London']])
    end

    it 'returns nil if it does not find a match' do
      expect(instance.deep_grep(/wahoo/)).to be_nil
    end
  end
end
