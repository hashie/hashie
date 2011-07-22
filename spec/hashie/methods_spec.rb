require 'spec_helper'

describe Hashie::Methods::DeepMerge do
  class DeepHash < Hash; include Hashie::Methods::DeepMerge end
  subject{ DeepHash.new }

  describe '#deep_update' do
    it 'should merge two hashes together and preserve subhashes' do
      pending
      subject[:abc] = {:def => 'ghi'}
      subject.deep_update :abc => {:jkl => 'mno'}
      subject[:abc].should == {:def => 'ghi', :jkl => 'mno'}
    end
  end
end
