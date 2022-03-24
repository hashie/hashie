ENV['RAILS_ENV'] = 'test'

require 'rspec/core'

RSpec.describe 'rails' do
  before do
    require 'bundler'
    require_relative 'app'
    require 'rspec/rails'
  end

  it 'uses rails7' do
    expect(Rails.version).to(eq("7.0.2.3"))
  end

  context '#deep_symbolize_keys' do
    let(:mash) do
      Hashie::Mash.new("shallow" => 1, "top-level" => { "deep" => 3, "nested" => 4 })
    end

    subject { mash.deep_symbolize_keys }

    it 'symbolizes keys by access' do
      expect(mash[:'top-level'][:deep]).to(eq(3))
    end

    it 'does not play well with #without, which calls each element directly' do
      expect(mash[:'top-level'].without(:deep, :nested)).to(be_blank)
    end

    it 'does play well with #except, which monkey-patches Hash' do
      expect(mash[:'top-level'].except(:deep, :nested)).to(be_blank)
    end
  end
end
