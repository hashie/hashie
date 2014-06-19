require 'spec_helper'

describe Hashie::Extensions::Dash::IndifferentAccess do
  class DashWithIndifferentAccess < Hashie::Dash
    include Hashie::Extensions::Dash::IndifferentAccess
    property :name
  end

  class TrashWithIndifferentAccess < Hashie::Trash
    include Hashie::Extensions::Dash::IndifferentAccess
    property :per_page, transform_with: lambda { |v| v.to_i }
    property :total, from: :total_pages
  end

  context 'when included in Trash' do
    let(:params) { { per_page: '1', total_pages: 2 } }
    subject { TrashWithIndifferentAccess.new(params) }

    it 'gets the expected behaviour' do
      expect(subject.per_page).to eq params[:per_page].to_i
      expect(subject.total).to eq params[:total_pages]
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
end
