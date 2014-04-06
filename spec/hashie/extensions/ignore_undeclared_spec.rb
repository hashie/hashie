require 'spec_helper'

describe Hashie::Extensions::IgnoreUndeclared do
  class ForgivingTrash < Hashie::Trash
    include Hashie::Extensions::IgnoreUndeclared
    property :city
    property :state, from: :provence
  end

  subject { ForgivingTrash }

  it 'silently ignores undeclared properties on initialization' do
    expect { subject.new(city: 'Toronto', provence: 'ON', country: 'Canada') }.to_not raise_error
  end

  it 'works with translated properties (with symbol keys)' do
    expect(subject.new(provence: 'Ontario').state).to eq('Ontario')
  end

  it 'works with translated properties (with string keys)' do
    expect(subject.new(provence: 'Ontario').state).to eq('Ontario')
  end
end
