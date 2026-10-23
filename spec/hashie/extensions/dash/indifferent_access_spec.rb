# frozen_string_literal: true

require 'spec_helper'

describe Hashie::Extensions::Dash::IndifferentAccess do
  class TrashWithIndifferentAccess < Hashie::Trash
    include Hashie::Extensions::Dash::IndifferentAccess

    property :per_page, transform_with: lambda(&:to_i)
    property :total, from: :total_pages
  end

  class DashWithIndifferentAccess < Hashie::Dash
    include Hashie::Extensions::Dash::IndifferentAccess

    property :name
  end

  context 'when included in Trash' do
    subject { TrashWithIndifferentAccess.new(params) }

    let(:params) { { per_page: '1', total_pages: 2 } }

    it 'gets the expected behaviour' do
      expect(subject.per_page).to eq params[:per_page].to_i
      expect(subject.total).to eq params[:total_pages]
    end
  end

  context 'when included in Dash' do
    let(:patch) { Hashie::Extensions::Dash::IndifferentAccess::ClassMethods }
    let(:dash_class) { Class.new(Hashie::Dash) }

    it 'extends with the patch once' do
      expect(patch).to receive(:extended).with(dash_class).once
      dash_class.send(:include, described_class)
    end
  end

  context 'initialized with' do
    it 'string' do
      instance = DashWithIndifferentAccess.new('name' => 'Name')
      expect(instance.name).to eq('Name')
      expect(instance['name']).to eq('Name')
      expect(instance[:name]).to eq('Name')
      expect(instance.inspect).to eq('#<DashWithIndifferentAccess name="Name">')
      expect(instance.to_hash).to eq('name' => 'Name')
    end

    it 'key' do
      instance = DashWithIndifferentAccess.new(name: 'Name')
      expect(instance.name).to eq('Name')
      expect(instance['name']).to eq('Name')
      expect(instance[:name]).to eq('Name')
      expect(instance.inspect).to eq('#<DashWithIndifferentAccess name="Name">')
      expect(instance.to_hash).to eq('name' => 'Name')
    end
  end

  it 'updates' do
    instance = DashWithIndifferentAccess.new
    instance['name'] = 'Updated String'
    expect(instance.name).to eq('Updated String')
    instance[:name] = 'Updated Symbol'
    expect(instance.name).to eq('Updated Symbol')
    instance.name = 'Updated Method'
    expect(instance.name).to eq('Updated Method')
  end

  context 'initialized with both prefers last assignment' do
    it 'string, then symbol' do
      instance = DashWithIndifferentAccess.new('name' => 'First', name: 'Last')
      expect(instance.name).to eq('Last')
      expect(instance['name']).to eq('Last')
      expect(instance[:name]).to eq('Last')
      expect(instance.inspect).to eq('#<DashWithIndifferentAccess name="Last">')
      expect(instance.to_hash).to eq('name' => 'Last')
    end

    it 'symbol then string' do
      instance = DashWithIndifferentAccess.new(name: 'Last', 'name' => 'First')
      expect(instance.name).to eq('First')
      expect(instance['name']).to eq('First')
      expect(instance[:name]).to eq('First')
      expect(instance.inspect).to eq('#<DashWithIndifferentAccess name="First">')
      expect(instance.to_hash).to eq('name' => 'First')
    end
  end

  context 'multiple properties translated from a nested hash' do
    [false, true].each do |string_source|
      [false, true].each do |indifferent_first|
        context "with #{string_source ? 'string' : 'symbol'} sources and " \
                "#{indifferent_first ? 'indifferent access' : 'ignore undeclared'} first" do
          let(:person_class) do
            source = string_source ? 'name' : :name
            first = indifferent_first
            Class.new(Hashie::Trash) do
              include(first ? Hashie::Extensions::IndifferentAccess : Hashie::Extensions::IgnoreUndeclared)
              include(first ? Hashie::Extensions::IgnoreUndeclared : Hashie::Extensions::IndifferentAccess)

              property :first_name, from: source, transform_with: ->(name) { name['first'] }
              property :last_name, from: source, transform_with: ->(name) { name['last'] }
            end
          end

          it 'accepts string and symbol input keys without losing either translation' do
            ['name', :name].each do |key|
              person = person_class.new(key => { 'first' => 'First', 'last' => 'Last' },
                                        'extra' => 1)
              expect(person.first_name).to eq('First')
              expect(person.last_name).to eq('Last')
              expect(person.key?('extra')).to be false
              expect(person_class.property?(key)).to be true
              expect(person_class.property?(:extra)).to be false
            end
          end

          it 'translates again inside a nested Trash' do
            nested_class = person_class
            envelope = Class.new(Hashie::Trash) do
              include Hashie::Extensions::IgnoreUndeclared
              include Hashie::Extensions::IndifferentAccess

              property :person, from: :record, transform_with: lambda { |record|
                nested_class.new(record)
              }
              property :identifier, from: :record, transform_with: ->(record) { record['id'] }
            end
            input = { 'record' => { 'id' => 42,
                                    'name' => { 'first' => 'First', 'last' => 'Last' } } }
            result = envelope.new(input)
            expect(result.identifier).to eq(42)
            expect(result.person.first_name).to eq('First')
            expect(result.person.last_name).to eq('Last')
          end
        end
      end
    end
  end

  it 'accepts a translation source that is also a declared destination without recursing' do
    klass = Class.new(Hashie::Trash) do
      include Hashie::Extensions::IgnoreUndeclared
      include Hashie::Extensions::IndifferentAccess

      property :name, from: :record, transform_with: ->(record) { record['name'] }
      property :initial, from: :name, transform_with: ->(name) { name[0] }
    end
    expect(klass.property?('record')).to be true
    expect(klass.new('record' => { 'name' => 'First' }).initial).to eq('F')
  end
end
