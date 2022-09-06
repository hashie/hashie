require 'spec_helper'

RSpec.describe Hashie::Extensions::Mash::UnderscoreKeys, :aggregate_failures do
  let(:underscore_mash) do
    Class.new(Hashie::Mash) do
      include Hashie::Extensions::Mash::UnderscoreKeys
    end
  end

  it 'allows access to keys via original name' do
    original = {
      dataFrom: { java: true, javaScript: true },
      DataSource: { GitHub: true },
      'created-at': 'today'
    }

    mash = underscore_mash.new(original)

    expect(mash.dataFrom.java).to be(true)
    expect(mash[:dataFrom][:java]).to be(true)
    expect(mash['dataFrom']['java']).to be(true)

    expect(mash.dataFrom.javaScript).to be(true)
    expect(mash[:dataFrom][:javaScript]).to be(true)
    expect(mash['dataFrom']['javaScript']).to be(true)

    expect(mash.DataSource.GitHub).to be(true)
    expect(mash[:DataSource][:GitHub]).to be(true)
    expect(mash['DataSource']['GitHub']).to be(true)

    # can't currently call a method with a hyphen
    # expect(mash.call(:'created-at')).to eq('today')
    expect(mash[:'created-at']).to eq('today')
    expect(mash['created-at']).to eq('today')
  end

  it 'allows access to underscore key names' do
    original = {
      dataFrom: { java: true, javaScript: true },
      DataSource: { GitHub: true },
      'created-at': 'today'
    }

    mash = underscore_mash.new(original)

    expect(mash.data_from.java).to be(true)
    expect(mash[:data_from][:java]).to be(true)
    expect(mash['data_from']['java']).to be(true)

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
end
