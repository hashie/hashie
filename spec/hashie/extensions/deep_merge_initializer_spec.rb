require 'spec_helper'

describe Hashie::Extensions::DeepMergeInitializer do
  class DeepInitializerHash < Hash
    include Hashie::Extensions::DeepMergeInitializer
  end

  subject { DeepInitializerHash }

  it 'creates nested hash with the same type as parent hash' do
    s = subject.new({ a: :b, hash: { c: :d } })[:hash]
    pp s.class
    expect(subject.new({ a: :b, hash: { c: :d } })[:hash]).to be_a(subject)
  end
end
