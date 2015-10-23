require 'spec_helper'

describe Hashie::Extensions::StrictKeyAccess do
  class StrictKeyAccessHash < Hash
    include Hashie::Extensions::StrictKeyAccess
  end

  shared_examples_for 'StrictKeyAccess with valid key' do |options = {}|
    before { pending_for(options[:pending]) } if options[:pending]
    context 'access' do
      it('returns value') do
        expect(instance[valid_key]).to eq valid_value
      end
    end
    context 'lookup' do
      it('returns key') do
        expect(instance.key(valid_value)).to eq valid_key
      end
    end
  end
  shared_examples_for 'StrictKeyAccess with invalid key' do |options = {}|
    before { pending_for(options[:pending]) } if options[:pending]
    context 'access' do
      it('raises an error') do
        # Formatting of the error message varies on Rubinius and ruby-head
        expect { instance[invalid_key] }.to raise_error KeyError
      end
    end
    context 'lookup' do
      it('raises an error') do
        # Formatting of the error message does not vary here because raised by StrictKeyAccess
        expect { instance.key(invalid_value) }.to raise_error KeyError,
                                                              %(key not found with value of #{invalid_value.inspect})
      end
    end
  end
  shared_examples_for 'StrictKeyAccess with exploding defaults' do
    context '#default' do
      it 'raises an error' do
        expect { instance.default(invalid_key) }.to raise_error Hashie::Extensions::StrictKeyAccess::DefaultError,
                                                                'Setting or using a default with Hashie::Extensions::StrictKeyAccess does not make sense'
      end
    end
    context '#default=' do
      it 'raises an error' do
        expect { instance.default = invalid_key }.to raise_error Hashie::Extensions::StrictKeyAccess::DefaultError,
                                                                 'Setting or using a default with Hashie::Extensions::StrictKeyAccess does not make sense'
      end
    end
    context '#default_proc' do
      it 'raises an error' do
        expect { instance.default_proc }.to raise_error Hashie::Extensions::StrictKeyAccess::DefaultError,
                                                        'Setting or using a default with Hashie::Extensions::StrictKeyAccess does not make sense'
      end
    end
    context '#default_proc=' do
      it 'raises an error' do
        expect { instance.default_proc = proc {} }.to raise_error Hashie::Extensions::StrictKeyAccess::DefaultError,
                                                                  'Setting or using a default with Hashie::Extensions::StrictKeyAccess does not make sense'
      end
    end
  end

  let(:klass) { StrictKeyAccessHash }
  let(:instance) { StrictKeyAccessHash.new(*args) }
  let(:args) do
    [
      { valid_key => valid_value }
    ]
  end
  let(:valid_key) { :abc }
  let(:valid_value) { 'def' }
  let(:invalid_key) { :mega }
  let(:invalid_value) { 'death' }

  context '.new' do
    it_behaves_like 'StrictKeyAccess with valid key'
    it_behaves_like 'StrictKeyAccess with invalid key'
    it_behaves_like 'StrictKeyAccess with exploding defaults'
  end

  context '[]' do
    let(:instance) { StrictKeyAccessHash[*args] }
    it_behaves_like 'StrictKeyAccess with valid key', pending: { engine: 'rbx' }
    it_behaves_like 'StrictKeyAccess with invalid key', pending: { engine: 'rbx' }
    it_behaves_like 'StrictKeyAccess with exploding defaults'
  end

  context 'with default' do
    let(:args) do
      [
        { valid_key => valid_value }, invalid_value
      ]
    end
    it_behaves_like 'StrictKeyAccess with valid key'
    it_behaves_like 'StrictKeyAccess with invalid key'
    it_behaves_like 'StrictKeyAccess with exploding defaults'
  end
end
