# frozen_string_literal: true

require 'logger'
require 'active_model'
require 'dry-types'
require 'hashie'

RSpec.describe 'external callable coercers' do
  let(:hash_class) do
    Class.new(Hash) do
      include Hashie::Extensions::Coercion
      include Hashie::Extensions::MergeInitializer
    end
  end

  let(:dash_class) do
    Class.new(Hashie::Dash) do
      include Hashie::Extensions::Dash::Coercion
    end
  end

  context 'with dry-types' do
    let(:boolean) { Dry::Types['params.bool'] }

    it 'uses the selected boolean policy' do
      hash_class.coerce_key :enabled, boolean
      [true, 'true', 1].each do |value|
        expect(hash_class.new(enabled: value)[:enabled]).to be(true)
      end
      [false, 'false', 0].each do |value|
        expect(hash_class.new(enabled: value)[:enabled]).to be(false)
      end
    end

    it 'does not apply Grape empty-string normalization' do
      hash_class.coerce_key :enabled, boolean
      expect { hash_class.new(enabled: '') }.to raise_error(Dry::Types::CoercionError)
    end

    it 'propagates invalid-input errors and preserves the stored value' do
      hash_class.coerce_key :enabled, boolean
      hash = hash_class.new(enabled: 'true')
      expect { hash[:enabled] = 123 }.to raise_error(Dry::Types::CoercionError)
      expect(hash[:enabled]).to be(true)
    end

    it 'supports strict types without coercing strings' do
      hash_class.coerce_key :enabled, Dry::Types['strict.bool']
      expect(hash_class.new(enabled: false)[:enabled]).to be(false)
      expect { hash_class.new(enabled: 'false') }.to raise_error(Dry::Types::ConstraintError)
    end

    it 'preserves the existing nil bypass even for a strict type' do
      hash_class.coerce_key :enabled, Dry::Types['strict.bool']
      expect(hash_class.new(enabled: nil)[:enabled]).to be_nil
    end

    it 'passes nil collection members to the selected type' do
      hash_class.coerce_key :enabled, [Dry::Types['strict.bool']]
      expect { hash_class.new(enabled: [nil]) }.to raise_error(Dry::Types::ConstraintError)
    end

    it 'coerces Dash properties during initialization and assignment' do
      dash_class.property :enabled, coerce: boolean
      dash = dash_class.new(enabled: 'true')
      expect(dash.enabled).to be(true)
      dash.enabled = 'false'
      expect(dash.enabled).to be(false)
    end

    it 'coerces nested collections without mutating frozen inputs' do
      hash_class.coerce_key(:settings, { Dry::Types['coercible.string'] => [boolean] })
      input = { enabled: %w[true false].freeze }.freeze
      hash = hash_class.new(settings: input)
      expect(hash[:settings]).to eq('enabled' => [true, false])
      expect(input).to eq(enabled: %w[true false])
    end

    it 'uses callable value coercion before Mash wrapping' do
      klass = Class.new(Hashie::Mash)
      klass.include Hashie::Extensions::Coercion
      klass.coerce_value Hash, Dry::Types['hash'].schema(enabled: boolean)
      expect(klass.new(settings: { enabled: 'false' }).settings[:enabled]).to be(false)
    end
  end

  context 'with ActiveModel' do
    let(:boolean) { ActiveModel::Type::Boolean.new.method(:cast) }

    it 'uses ActiveModel boolean semantics rather than dry-types semantics' do
      hash_class.coerce_key :enabled, boolean
      expect(hash_class.new(enabled: 'off')[:enabled]).to be(false)
      expect(hash_class.new(enabled: '')[:enabled]).to be_nil
      expect(hash_class.new(enabled: 'unknown')[:enabled]).to be(true)
    end

    it 'coerces Dash properties using a bound cast method' do
      dash_class.property :enabled, coerce: boolean
      dash = dash_class.new(enabled: 'off')
      expect(dash.enabled).to be(false)
      dash.enabled = 'on'
      expect(dash.enabled).to be(true)
    end
  end
end
