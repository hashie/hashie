require 'spec_helper'

describe Hashie::Extensions::DeepMerge do
  class DeepMergeHash < Hash; include Hashie::Extensions::DeepMerge end

  subject{ DeepMergeHash }

  let(:h1) { subject.new.merge(:a => "a", :b => "b", :c => { :c1 => "c1", :c2 => "c2", :c3 => { :d1 => "d1" } }) }
  let(:h2) { { :a => 1, :c => { :c1 => 2, :c3 => { :d2 => "d2" } } } }
  let(:expected_hash) { { :a => 1, :b => "b", :c => { :c1 => 2, :c2 => "c2", :c3 => { :d1 => "d1", :d2 => "d2" } } } }

  it 'should deep merge two hashes' do
    h1.deep_merge(h2).should == expected_hash
  end

  it 'should deep merge two hashes with bang method' do
    h1.deep_merge!(h2)
    h1.should == expected_hash
  end
end
