require 'spec_helper'

describe Hashie::Rash do
  subject do
    Hashie::Rash.new(
      /hello/ => 'hello',
      /world/ => 'world',
      'other' => 'whee',
      true    => false,
      1       => 'awesome',
      1..1000 => 'rangey',
      /(bcd)/ => proc { |m| m[1] }
      # /.+/ => "EVERYTHING"
    )
  end

  it 'finds strings' do
    subject['other'].should eq 'whee'
    subject['well hello there'].should eq 'hello'
    subject['the world is round'].should eq 'world'
    subject.all('hello world').sort.should eq %w(hello world)
  end

  it 'finds regexps' do
    subject[/other/].should eq 'whee'
  end

  it 'finds other objects' do
    subject[true].should eq false
    subject[1].should eq 'awesome'
  end

  it 'finds numbers from ranges' do
    subject[250].should eq 'rangey'
    subject[999].should eq 'rangey'
    subject[1000].should eq 'rangey'
    subject[1001].should be_nil
  end

  it 'evaluates proc values' do
    subject['abcdef'].should eq 'bcd'
    subject['ffffff'].should be_nil
  end
end
