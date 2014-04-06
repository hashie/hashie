require 'spec_helper'

describe Hashie::Extensions::DeepMerge do
  class DeepMergeHash < Hash
    include Hashie::Extensions::DeepMerge
  end

  subject { DeepMergeHash }

  let(:h1) { subject.new.merge(a: 'a', a1: 42, b: 'b', c: { c1: 'c1', c2: { a: 'b' }, c3: { d1: 'd1' } }) }
  let(:h2) { { a: 1, a1: 1, c: { c1: 2, c2: 'c2', c3: { d2: 'd2' } } } }
  let(:expected_hash) { { a: 1, a1: 1, b: 'b', c: { c1: 2, c2: 'c2', c3: { d1: 'd1', d2: 'd2' } } } }

  it 'deep merges two hashes' do
    expect(h1.deep_merge(h2)).to eq expected_hash
  end

  it 'deep merges another hash in place via bang method' do
    h1.deep_merge!(h2)
    expect(h1).to eq expected_hash
  end
end
