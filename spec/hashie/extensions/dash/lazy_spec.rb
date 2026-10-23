# frozen_string_literal: true

require 'spec_helper'

describe Hashie::Extensions::Dash::Lazy do
  let(:dash_class) do
    Class.new(Hashie::Dash) do
      include Hashie::Extensions::Dash::Lazy

      property :name, required: true
      property :active
      property :address
    end
  end
  let(:calls) { [] }
  let(:values) { { name: 'Ada', active: false, address: nil } }
  let(:dash) do
    dash_class.new do |key|
      calls << key
      values[key]
    end
  end

  it 'does no loading at construction and memoizes only the accessed properties' do
    expect(dash.keys).to be_empty
    expect(calls).to be_empty
    2.times do
      expect(dash.name).to eq('Ada')
      expect(dash[:active]).to be(false)
      expect(dash.address).to be_nil
    end
    expect(calls).to eq(%i[name active address])
  end

  it 'raises for missing required values only on access and can retry' do
    values.delete(:name)
    expect(dash).to be_empty
    expect { dash.name }.to raise_error(ArgumentError, /the property `name`/)
    values[:name] = 'Grace'
    expect(dash.name).to eq('Grace')
    expect(calls).to eq(%i[name name])
  end

  it 'does not invoke the loader for undeclared properties' do
    expect { dash[:missing] }.to raise_error(NoMethodError)
    expect(calls).to be_empty
  end

  it 'lets explicit assignments and merges override pending values' do
    dash.name = 'Grace'
    dash.merge!(active: true)
    expect(dash.name).to eq('Grace')
    expect(dash.active).to be(true)
    expect(calls).to be_empty
    expect { dash.name = nil }.to raise_error(ArgumentError)
  end

  it 'supports targeted fetch and dig, including missing-key behavior' do
    values[:address] = { city: 'London' }
    expect(dash.fetch(:name)).to eq('Ada')
    expect(dash.dig(:address, :city)).to eq('London')
    expect(dash.fetch(:missing, 'fallback')).to eq('fallback')
    expect(dash.fetch(:missing) { |key| key }).to eq(:missing)
    expect { dash.fetch(:missing) }.to raise_error(KeyError)
    expect(dash.dig(:missing, :city)).to be_nil
    expect(calls).to eq(%i[name address])
  end

  it 'materializes every declared property for hash conversion' do
    expect(dash.to_h).to eq(values)
    expect(dash.to_hash).to eq(values)
    expect(calls).to eq(%i[name active address])
  end

  it 'retains eager initialization and required checks without a loader' do
    expect(dash_class.new(name: 'Grace').name).to eq('Grace')
    expect { dash_class.new }.to raise_error(ArgumentError, /the property `name`/)
  end

  it 'uses initial attributes without calling the loader for them' do
    instance = dash_class.new(name: 'Grace') do |key|
      calls << key
      values[key]
    end
    expect(instance.keys).to be_empty
    expect(instance.name).to eq('Grace')
    expect(instance.active).to be(false)
    expect(calls).to eq([:active])
  end

  it 'keeps loading state independent when duplicated' do
    copy = dash.dup
    expect(copy.name).to eq('Ada')
    values[:name] = 'Grace'
    expect(dash.name).to eq('Grace')
    expect(calls).to eq(%i[name name])
  end

  it 'materializes before freezing so reads remain possible' do
    expect(dash.freeze).to be_frozen
    expect(dash.name).to eq('Ada')
    expect(dash.address).to be_nil
    expect(calls).to eq(%i[name active address])
    expect { dash.active = true }.to raise_error(FrozenError)
  end

  it 'propagates loader errors and retries rather than caching failures' do
    attempts = 0
    instance = dash_class.new do |_key|
      attempts += 1
      raise IOError, 'source unavailable' if attempts == 1

      'Ada'
    end
    expect { instance.name }.to raise_error(IOError, 'source unavailable')
    expect(instance.name).to eq('Ada')
  end

  it 'reports recursive loading and clears the in-progress state' do
    instance = dash_class.new { |_key| instance.name }
    2.times do
      expect { instance.name }.to raise_error(ArgumentError, 'circular lazy loading for property `name`')
    end
  end

  it 'evaluates and copies defaults only when the property is read' do
    defaults = []
    klass = Class.new(dash_class) do
      property :active, default: lambda { |record|
        defaults << record.name
        false
      }
      property :address, default: []
    end
    first = klass.new { |key| values[key] }
    second = klass.new { |key| values[key] }
    expect(defaults).to be_empty
    expect(first.active).to be(false)
    expect(defaults).to be_empty
    values[:active] = nil
    expect(second.active).to be(false)
    expect(defaults).to eq(['Ada'])
    first.address << 'London'
    expect(second.address).to eq([])
  end

  it 'loads conditional required dependencies on access' do
    klass = Class.new(dash_class) { property :address, required: :active }
    instance = klass.new do |key|
      calls << key
      values[key]
    end
    expect(instance.address).to be_nil
    instance.active = true
    expect { instance.address }.to raise_error(ArgumentError, /the property `address`/)
    expect(calls).to eq(%i[address active])
  end

  it 'supports indifferent reads and memoizes nil values with string storage keys' do
    klass = Class.new(Hashie::Dash) do
      include Hashie::Extensions::Dash::IndifferentAccess
      include Hashie::Extensions::Dash::Lazy

      property :name
      property :address
    end
    instance = klass.new do |key|
      calls << key
      values[key]
    end
    expect(instance['name']).to eq('Ada')
    expect(instance.name).to eq('Ada')
    expect(instance.address).to be_nil
    expect(instance['address']).to be_nil
    expect(instance.to_h).to eq('name' => 'Ada', 'address' => nil)
    expect(calls).to eq(%i[name address])

    supplied = klass.new('name' => 'Grace', 'address' => nil) { |_key| raise 'unexpected load' }
    expect(supplied.to_h).to eq('name' => 'Grace', 'address' => nil)
  end

  context 'with Trash transformations and Dash coercion' do
    let(:transforms) { [] }
    let(:trash_class) do
      transformations = transforms
      Class.new(Hashie::Trash) do
        include Hashie::Extensions::Dash::Coercion
        include Hashie::Extensions::Dash::Lazy

        property :age, from: :years, with: lambda { |value|
          transformations << :age
          value.to_i
        }
        property :next_age, from: :years, with: lambda { |value|
          transformations << :next_age
          value.to_i + 1
        }
        property :name, transform_with: lambda { |value|
          transformations << :name
          value.upcase
        }
        property :count, coerce: Integer
      end
    end

    it 'transforms only the requested destination even when input keys are shared' do
      instance = trash_class.new do |key|
        calls << key
        '37'
      end
      expect(transforms).to be_empty
      expect(instance.age).to eq(37)
      expect(instance.age).to eq(37)
      expect(transforms).to eq([:age])
      expect(calls).to eq([:years])
      expect(instance.next_age).to eq(38)
      expect(transforms).to eq(%i[age next_age])
    end

    it 'defers canonical transformations and coercion' do
      instance = trash_class.new do |key|
        calls << key
        key == :name ? 'ada' : '37'
      end
      expect(calls).to be_empty
      expect(instance.name).to eq('ADA')
      expect(instance.count).to eq(37)
      expect(transforms).to eq([:name])
      expect(calls).to eq(%i[name count])
    end

    it 'accepts translated input attributes and explicit canonical overrides' do
      instance = trash_class.new(years: '37', age: 42) { |_key| raise 'unexpected load' }
      expect(instance.age).to eq(42)
      expect(instance.next_age).to eq(38)
      expect(transforms).to eq([:next_age])
    end

    it 'propagates transformation errors without caching a failed value' do
      value = 37
      instance = trash_class.new { |_key| value }
      expect { instance.name }.to raise_error(NoMethodError, /upcase/)
      value = 'ada'
      expect(instance.name).to eq('ADA')
      expect(transforms).to eq(%i[name name])
    end

    it 'does not construct nested objects until the corresponding property is read' do
      child_class = dash_class
      load_calls = calls
      klass = Class.new(Hashie::Trash) do
        include Hashie::Extensions::Dash::Lazy

        property :child, transform_with: lambda { |source|
          child_class.new { |key|
            load_calls << key
            source[key]
          }
        }
      end
      instance = klass.new { |_key| values }
      expect(calls).to be_empty
      child = instance.child
      expect(child.keys).to be_empty
      expect(calls).to be_empty
      expect(child.name).to eq('Ada')
      expect(calls).to eq([:name])
    end
  end
end
