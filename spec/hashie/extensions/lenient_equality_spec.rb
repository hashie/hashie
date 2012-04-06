require 'spec_helper'

describe Hashie::Extensions::LenientEquality do
  class LenientHash < ::Hash
    include Hashie::Extensions::MergeInitializer
    include Hashie::Extensions::LenientEquality
  end
  
  describe 'order unimportance' do

    describe 'of top-level keys' do
      let( :hash ){ { :foo => 'bar', :baz => 'woo' } }
      subject { LenientHash.new hash }

      it { should eql( { :foo => 'bar', :baz => 'woo' } ) }
      it { should eql( { :baz => 'woo', :foo => 'bar' } ) }
    end

    describe 'of nested keys' do
      let( :hash ){
        {
          :foo => 'bar',
          :baz => { :a => 1, :b => 2 }
        }
      }
      subject { LenientHash.new hash }

      it { should eql(
        {
          :foo => 'bar',
          :baz => { :b => 2, :a => 1 }
        }
      ) }
    end

    describe 'of arrays' do
      let( :hash ){ { :foo => [ 1, 2, 3 ] } }
      subject { LenientHash.new hash }

      it { should eql( { :foo => [ 1, 2, 3 ] } ) }
      it { should eql( { :foo => [ 3, 2, 1 ] } ) }
    end

    describe 'of nested arrays' do
      let( :hash ){ { :foo => [ { :bar => [ 1, 2, 3 ] }, { :baz => [ 1, 2, 3 ] } ] } }
      subject { LenientHash.new hash }

      it { should eql( { :foo => [ { :baz => [ 3, 2, 1 ] }, { :bar => [ 2, 1, 3 ] } ] } ) }
    end
  end

  describe 'extra keys' do
    let( :hash ){ { :foo => 'bar', :baz => 'woo' } }
    subject { LenientHash.new hash }

    it { should eql( { :foo => 'bar', :baz => 'woo', :abc => '123' } ) }
  end

  describe 'missing keys' do
    let( :hash ){ { :foo => 'bar', :baz => 'woo', :abc => '123' } }
    subject { LenientHash.new hash }

    it { should_not eql( { :foo => 'bar', :baz => 'woo' } ) }
  end
end
