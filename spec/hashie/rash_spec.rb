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
    expect(subject['other']).to eq 'whee'
    expect(subject['well hello there']).to eq 'hello'
    expect(subject['the world is round']).to eq 'world'
    expect(subject.all('hello world').sort).to eq %w(hello world)
  end

  it 'finds regexps' do
    expect(subject[/other/]).to eq 'whee'
  end

  it 'finds other objects' do
    expect(subject[true]).to eq false
    expect(subject[1]).to eq 'awesome'
  end

  it 'finds numbers from ranges' do
    expect(subject[250]).to eq 'rangey'
    expect(subject[999]).to eq 'rangey'
    expect(subject[1000]).to eq 'rangey'
    expect(subject[1001]).to be_nil
  end

  it 'evaluates proc values' do
    expect(subject['abcdef']).to eq 'bcd'
    expect(subject['ffffff']).to be_nil
  end
end
