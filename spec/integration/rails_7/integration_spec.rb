ENV['RAILS_ENV'] = 'test'

require 'logger' # https://github.com/rails/rails/issues/54260
require 'rspec/core'

RSpec.describe 'rails', type: :request do
  let(:stdout) { StringIO.new }

  around(:each) do |example|
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

  context '#except' do
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

  context '#deep_transform_keys' do
    let(:klass) do
      Class.new(Hashie::Dash) do
        property :foo_bar
        property :foo_baz, required: true
      end
    end

    subject(:hash) { klass.new(foo_bar: 'bar', foo_baz: 'baz') }

    it 'successfully deep transforms keys' do
      transformed = hash.deep_transform_keys(&:to_s)
      expect(transformed.keys).to all(be_a(String))
    end
  end

  context '#deep_merge with ActiveRecord values (#572)' do
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

    let(:diagram) { DeepMergeDiagram.instantiate('id' => 1, 'name' => 'Original') }
    let(:context_class) { Class.new(Hash) { include Hashie::Extensions::DeepMerge } }
    let(:preserving_class) do
      Class.new(context_class) do
        protected

        def deep_merge_copy_value(value)
          value.is_a?(ActiveRecord::Base) ? value : super
        end
      end
    end

    it 'reproduces the reported incoming id reset with the unchanged default policy' do
      result = context_class[{}].deep_merge(context_class[diagram: diagram])

      expect(result[:diagram]).to be_a(ActiveRecord::Base)
      expect(result[:diagram]).not_to equal(diagram)
      expect(result[:diagram].id).to be_nil
      expect(result[:diagram]).to be_new_record
      expect(diagram.id).to eq(1)
      expect(diagram).to be_persisted
    end

    it 'also resets ids when duplicating receiver values by default' do
      result = context_class[diagram: diagram].deep_merge({})

      expect(result[:diagram]).not_to equal(diagram)
      expect(result[:diagram].id).to be_nil
      expect(diagram.id).to eq(1)
    end

    %i[deep_merge deep_merge!].each do |operation|
      it "preserves incoming record identity and id on opt-in with #{operation}" do
        incoming = { nested: { diagram: diagram } }
        result = preserving_class.new.public_send(operation, incoming)

        expect(result[:nested][:diagram]).to equal(diagram)
        expect(result[:nested][:diagram].id).to eq(1)
        expect(result[:nested][:diagram]).to be_persisted
        expect(result[:nested]).not_to equal(incoming[:nested])
        result[:nested][:extra] = true
        expect(incoming[:nested].keys).to eq([:diagram])
      end
    end

    it 'preserves receiver record identity while copying surrounding hashes on opt-in' do
      receiver = preserving_class[nested: { diagram: diagram, text: +'original' }]
      result = receiver.deep_merge({})

      expect(result[:nested][:diagram]).to equal(diagram)
      expect(result[:nested][:diagram].id).to eq(1)
      expect(result[:nested]).not_to equal(receiver[:nested])
      result[:nested][:text].replace('changed')
      expect(receiver[:nested][:text]).to eq('original')
    end

    it 'keeps shallow receiver and deep incoming array copies without walking the hook' do
      diagrams = [diagram]
      result = preserving_class[existing: diagrams].deep_merge(added: diagrams)

      expect(result[:existing]).not_to equal(diagrams)
      expect(result[:existing].first).to equal(diagram)
      expect(result[:added]).not_to equal(diagrams)
      expect(result[:added].first).not_to equal(diagram)
      expect(result[:added].first.id).to be_nil
      expect(diagram.id).to eq(1)
    end
  end

  it 'works' do
    get '/'
    assert_select 'h1', 'Hello, world!'
  end
end
