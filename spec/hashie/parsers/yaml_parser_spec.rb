# frozen_string_literal: true

require 'spec_helper'

describe Hashie::Extensions::Parsers::YamlParser do
  describe '.perform' do
    it 'parses YAML without evaluating ERB' do
      content = "---\nvalue: \"<%= 'plain' %>\"\n"
      expect(File).to receive(:read).with('config.yml').and_return(content)

      expect(described_class.perform('config.yml')).to eq('value' => "<%= 'plain' %>")
    end

    it 'preserves the safe-load YAML options' do
      expect do
        described_class.perform('spec/fixtures/yaml_with_symbols.yml')
      end.to raise_error(Psych::DisallowedClass, /Symbol/)

      mash = described_class.perform(
        'spec/fixtures/yaml_with_symbols.yml',
        permitted_classes: [Symbol],
        permitted_symbols: %i[user_icon width height]
      )
      expect(mash[:user_icon][:width]).to eq(200)

      expect do
        described_class.perform('spec/fixtures/yaml_with_aliases.yml', aliases: false)
      end.to raise_error(Psych::BadAlias)
    end
  end
end
