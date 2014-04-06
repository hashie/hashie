require 'spec_helper'

describe Hashie::Extensions::IgnoreUndeclared do
  class ForgivingTrash < Hashie::Trash
    include Hashie::Extensions::IgnoreUndeclared
    property :city
    property :state, from: :provence
  end

  subject { ForgivingTrash }

  it 'should silently ignore undeclared properties on initialization' do
    expect { subject.new(city: 'Toronto', provence: 'ON', country: 'Canada') }.to_not raise_error
  end

  it 'should work with translated properties (with symbol keys)' do
    expect(subject.new(provence: 'Ontario').state).to eq('Ontario')
  end

  it 'should work with translated properties (with string keys)' do
    expect(subject.new(provence: 'Ontario').state).to eq('Ontario')
  end
end
