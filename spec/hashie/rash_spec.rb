require 'spec_helper'

describe Hashie::Rash do

  attr_accessor :r

  before :each do
    @r = Hashie::Rash.new(
      /hello/ => 'hello',
      /world/ => 'world',
      'other' => 'whee',
      true    => false,
      1       => 'awesome',
      1..1000 => 'rangey',
      # /.+/ => "EVERYTHING"
    )
  end

  it 'should lookup strings' do
    r['other'].should eq 'whee'
    r['well hello there'].should eq 'hello'
    r['the world is round'].should eq 'world'
    r.all('hello world').sort.should eq %w(hello world)
  end

  it 'should lookup regexps' do
    r[/other/].should eq 'whee'
  end

  it 'should lookup other objects' do
    r[true].should eq false
    r[1].should eq 'awesome'
  end

  it 'should lookup numbers from ranges' do
    @r[250].should eq 'rangey'
    @r[999].should eq 'rangey'
    @r[1000].should eq 'rangey'
    @r[1001].should be_nil
  end

  it 'should call values which are procs' do
    r = Hashie::Rash.new(/(ello)/ => proc { |m| m[1] })
    r['hello'].should eq 'ello'
    r['ffffff'].should be_nil
  end

end
