require 'spec_helper'

describe Hashie::Slash do

  describe 'equality' do
    subject { Hashie::Slash.new :foo => 'bar', :baz => 'woo' }

    it { should eql( { :foo => 'bar', :baz => 'woo' } ) }
    it { should eql( { :baz => 'woo', :foo => 'bar' } ) }
  end
end
