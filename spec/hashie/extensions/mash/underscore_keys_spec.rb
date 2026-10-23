# frozen_string_literal: true

require 'spec_helper'

describe Hashie::Extensions::Mash::UnderscoreKeys do
  let(:klass) do
    Class.new(Hashie::Mash) do
      include Hashie::Extensions::Mash::UnderscoreKeys
    end
  end

  it 'normalizes camelCase, PascalCase, acronyms, hyphens and digit boundaries' do
    {
      'updatedAt' => 'updated_at',
      'DataSource' => 'data_source',
      'HTTPServer' => 'http_server',
      'GitHub' => 'git_hub',
      'created-at' => 'created_at',
      'version2Value' => 'version2_value',
      'already_normalized' => 'already_normalized'
    }.each do |original, normalized|
      mash = klass.new(original => 'value')
      expect(mash.keys).to eq([normalized])
      expect(mash[original.to_sym]).to eq('value')
      expect(mash[normalized]).to eq('value')
      expect(klass.new(normalized => 'value').keys).to eq([normalized])
    end
  end

  it 'supports original and normalized method access throughout nested containers' do
    mash = klass.new(dataFrom: { javaScript: true }, otherItems: [{ createdAt: 'today' }])
    expect(mash.dataFrom.java_script).to be true
    expect(mash.data_from.javaScript).to be true
    expect(mash.other_items.first.created_at).to eq('today')
    mash.updatedAt = 'tomorrow'
    expect(mash.updated_at).to eq('tomorrow')
    expect(mash.fetch(:updatedAt)).to eq('tomorrow')
    expect(mash.key?('updatedAt')).to be true
    expect(mash.delete(:updatedAt)).to eq('tomorrow')
  end

  it 'uses last assignment for normalized collisions without modifying frozen input keys' do
    key = 'updatedAt'
    mash = klass.new(key => 1, 'updated_at' => 2, 42 => 3, nil => 4)
    expect(mash.to_h).to eq('updated_at' => 2, 42 => 3, nil => 4)
    expect(key).to eq('updatedAt')
  end

  it 'does not attempt to make arbitrary punctuation or spaces method-safe' do
    mash = klass.new('created at' => 1, 'API::Client' => 2)
    expect(mash.to_h).to eq('created at' => 1, 'api::client' => 2)
  end

  it 'inherits normalization and permits independent custom overrides' do
    child = Class.new(klass)
    child.transform_keys_with { |key| key.delete('-').downcase }
    expect(child.new('GitHub' => 1).keys).to eq(['github'])
    expect(klass.new('GitHub' => 1).keys).to eq(['git_hub'])
    expect(Class.new(klass).new('GitHub' => 1).keys).to eq(['git_hub'])
  end

  it 'rejects inclusion outside Mash' do
    expect { Class.new(Hash) { include Hashie::Extensions::Mash::UnderscoreKeys } }
      .to raise_error(ArgumentError, /must descend from Hashie::Mash/)
  end
end
