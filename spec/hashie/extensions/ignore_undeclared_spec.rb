require 'spec_helper'

describe Hashie::Extensions::IgnoreUndeclared do
  class ForgivingTrash < Hashie::Trash
    include Hashie::Extensions::IgnoreUndeclared
    property :city
  end

  subject{ ForgivingTrash }

  it 'should silently ignore undeclared properties on initialization' do
    lambda { subject.new(:city => 'Pittsburgh', :state => 'PA') }.should_not raise_error
  end
end
