require 'spec_helper'

RSpec.describe Hashie::Extensions::Mash::UnderscoreKeys, :aggregate_failures do
  let(:underscore_mash) do
    Class.new(Hashie::Mash) do
      include Hashie::Extensions::Mash::UnderscoreKeys
    end
  end

  it 'allows access to keys via original name' do
    original = {
      dataFrom: { swift: true, javaScript: true },
      DataSource: { GitHub: true },
      'created-at': 'today'
    }

    mash = underscore_mash.new(original)

    expect(mash.dataFrom.swift).to be(true)
    expect(mash[:dataFrom][:swift]).to be(true)
    expect(mash['dataFrom']['swift']).to be(true)

    expect(mash.dataFrom.javaScript).to be(true)
    expect(mash[:dataFrom][:javaScript]).to be(true)
    expect(mash['dataFrom']['javaScript']).to be(true)

    expect(mash.DataSource.GitHub).to be(true)
    expect(mash[:DataSource][:GitHub]).to be(true)
    expect(mash['DataSource']['GitHub']).to be(true)

    expect(mash.send('created-at')).to eq('today')
    expect(mash[:'created-at']).to eq('today')
    expect(mash['created-at']).to eq('today')
  end

  it 'allows access to underscore key names' do
    original = {
      dataFrom: { swift: true, javaScript: true },
      DataSource: { GitHub: true },
      'created-at': 'today'
    }

    mash = underscore_mash.new(original)

    expect(mash.data_from.swift).to be(true)
    expect(mash[:data_from][:swift]).to be(true)
    expect(mash['data_from']['swift']).to be(true)

    expect(mash.data_from.java_script).to be(true)
    expect(mash[:data_from][:java_script]).to be(true)
    expect(mash['data_from']['java_script']).to be(true)

    expect(mash.data_source.git_hub).to be(true)
    expect(mash[:data_source][:git_hub]).to be(true)
    expect(mash['data_source']['git_hub']).to be(true)

    expect(mash.created_at).to eq('today')
    expect(mash[:'created-at']).to eq('today')
    expect(mash['created-at']).to eq('today')
  end

  it 'allows mixing and matching of underscore and camelCase' do
    original = {
      dataFrom: { java: true, javaScript: true },
      DataSource: { GitHub: true },
      'created-at': 'today'
    }

    mash = underscore_mash.new(original)

    expect(mash.dataFrom.java_script).to be(true)
    expect(mash[:data_from][:javaScript]).to be(true)
    expect(mash['dataFrom']['java_script']).to be(true)

    expect(mash.DataSource.git_hub).to be(true)
    expect(mash[:data_source][:GitHub]).to be(true)
    expect(mash['DataSource']['git_hub']).to be(true)
  end

  it 'converts spaces to underscore' do
    original = { 'hashie mashie': 'mashie hashie' }

    mash = underscore_mash.new(original)

    expect(mash.hashie_mashie).to eq('mashie hashie')
  end

  it 'converts spaces to underscore' do
    original = { 'hashie mashie?': true }

    mash = underscore_mash.new(original)

    expect(mash.hashie_mashie?).to be(true)
  end

  context 'when setting acronyms override' do
    before do
      Hashie::Extensions::Mash::UnderscoreKeys::ACRONYMS[:GH] = :GitHub
    end

    it 'does not break apart with underscore, but does downcase' do
      original = { GitHub: true }

      mash = underscore_mash.new(original)

      expect(mash.github).to be(true)
      expect(mash.git_hub).to be(nil)
    end
  end
end
