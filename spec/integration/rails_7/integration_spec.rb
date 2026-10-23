# frozen_string_literal: true

ENV['RAILS_ENV'] = 'test'

require 'logger' # https://github.com/rails/rails/issues/54260
require 'rspec/core'

RSpec.describe 'rails', type: :request do
  let(:stdout) { StringIO.new }

  around do |example|
    original_stdout = $stdout
    $stdout = stdout
    require_relative 'app'
    require 'rspec/rails'
    example.run
    $stdout = original_stdout
  end

  it 'does not log anything to STDOUT when initializing' do
    expect(stdout.string).to eq('')
  end

  it 'sets the Hashie logger to the Rails logger' do
    expect(Hashie.logger).to eq(Rails.logger)
  end

  context 'DeepMerge with ActiveRecord values' do
    before do
      require 'active_record'
      require 'active_support/core_ext/object/deep_dup'

      stub_const('DeepMergeDiagram', Class.new(ActiveRecord::Base) do
        self.primary_key = 'id'

        # Supply schema metadata only; initialization and duplication use ActiveRecord itself.
        def self.table_exists?
          true
        end

        def self.load_schema!
          @columns_hash = {}
          define_attribute('id', ActiveRecord::Type::Integer.new)
          define_attribute('name', ActiveRecord::Type::String.new)
        end
      end)
    end

    let(:record) { DeepMergeDiagram.instantiate('id' => 1, 'name' => 'Diagram') }
    let(:hash_class) do
      Class.new(Hash) { include Hashie::Extensions::DeepMerge }
    end

    it 'reproduces the domain-specific semantics of model duplication' do
      copy = record.dup
      expect(record.id).to eq(1)
      expect(record).to be_persisted
      expect(copy.id).to be_nil
      expect(copy).to be_new_record
    end

    %i[deep_merge deep_merge!].each do |operation|
      it "preserves model identity and persistence state on both sides of #{operation}" do
        receiver = hash_class[existing: { items: [record] }]
        result = receiver.public_send(operation, added: { items: [record] })

        expect(result[:existing][:items].first).to equal(record)
        expect(result[:added][:items].first).to equal(record)
        expect(record.id).to eq(1)
        expect(record).to be_persisted
      end
    end
  end

  describe '#except' do
    subject { Hashie::Mash.new(x: 1, y: 2) }

    it 'returns an instance of the class it was called on' do
      class HashieKlass < Hashie::Mash; end
      hashie_klass = HashieKlass.new(subject)
      expect(hashie_klass.except('x')).to be_a HashieKlass
    end

    it 'works with string keys' do
      expect(subject.except('x')).to eq Hashie::Mash.new(y: 2)
    end

    it 'works with symbol keys' do
      expect(subject.except(:x)).to eq Hashie::Mash.new(y: 2)
    end
  end

  describe '#deep_transform_keys' do
    subject(:hash) { klass.new(foo_bar: 'bar', foo_baz: 'baz') }

    let(:klass) do
      Class.new(Hashie::Dash) do
        property :foo_bar
        property :foo_baz, required: true
      end
    end

    it 'successfully deep transforms keys' do
      transformed = hash.deep_transform_keys(&:to_s)
      expect(transformed.keys).to all(be_a(String))
    end
  end

  it 'renders the application page' do
    get '/'
    assert_select 'h1', 'Hello, world!'
  end
end
