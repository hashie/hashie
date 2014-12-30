require 'spec_helper'

describe Hashie::Extensions::Mash::SafeAssignment do
  class MashWithSafeAssignment < Hashie::Mash
    include Hashie::Extensions::Mash::SafeAssignment
  end

  context 'when included in Mash' do
    subject { MashWithSafeAssignment.new }

    context 'when attempting to override a method' do
      it 'raises an error' do
        expect { subject.zip = 'Test' }.to raise_error(ArgumentError)
      end
    end

    context 'when setting as a hash key' do
      it 'still raises if conflicts with a method' do
        expect { subject[:zip] = 'Test' }.to raise_error(ArgumentError)
      end
    end
  end
end
