require 'active_support'
require 'active_support/core_ext'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/hash'
require 'hashie'

RSpec.configure do |config|
  config.expect_with :rspec do |expect|
    expect.syntax = :expect
  end
end

RSpec.describe Hashie::Mash do
  describe '#extractable_options?' do
    subject { Hashie::Mash.new(name: 'foo') }
    let(:args) { [101, 'bar', subject] }

    it 'can be extracted from an array' do
      expect(args.extract_options!).to eq subject
      expect(args).to eq [101, 'bar']
    end
  end
end

RSpec.describe Hashie::Extensions::DeepFind do
  let(:hash) do
    {
      library: {
        books: [
          { title: 'Call of the Wild' },
          { title: 'Moby Dick' }
        ],
        shelves: nil,
        location: {
          address: '123 Library St.',
          title: 'Main Library'
        }
      }
    }
  end

  subject(:instance) { hash.with_indifferent_access.extend(Hashie::Extensions::DeepFind) }

  describe '#deep_find' do
    it 'indifferently detects a value from a nested hash' do
      expect(instance.deep_find(:address)).to eq('123 Library St.')
      expect(instance.deep_find('address')).to eq('123 Library St.')
    end

    it 'indifferently detects a value from a nested array' do
      expect(instance.deep_find(:title)).to eq('Call of the Wild')
      expect(instance.deep_find('title')).to eq('Call of the Wild')
    end

    it 'indifferently returns nil if it does not find a match' do
      expect(instance.deep_find(:wahoo)).to be_nil
      expect(instance.deep_find('wahoo')).to be_nil
    end
  end

  describe '#deep_find_all' do
    it 'indifferently detects all values from a nested hash' do
      expect(instance.deep_find_all(:title))
        .to eq(['Call of the Wild', 'Moby Dick', 'Main Library'])
      expect(instance.deep_find_all('title'))
        .to eq(['Call of the Wild', 'Moby Dick', 'Main Library'])
    end

    it 'indifferently returns nil if it does not find any matches' do
      expect(instance.deep_find_all(:wahoo)).to be_nil
      expect(instance.deep_find_all('wahoo')).to be_nil
    end
  end
end

RSpec.describe Hashie::Extensions::DeepLocate do
  let(:hash) do
    {
      from: 0,
      size: 25,
      query: {
        bool: {
          must: [
            {
              query_string: {
                query: 'foobar',
                default_operator: 'AND',
                fields: [
                  'title^2',
                  '_all'
                ]
              }
            },
            {
              match: {
                field_1: 'value_1'
              }
            },
            {
              range: {
                lsr09: {
                  gte: 2014
                }
              }
            }
          ],
          should: [
            {
              match: {
                field_2: 'value_2'
              }
            }
          ],
          must_not: [
            {
              range: {
                lsr10: {
                  gte: 2014
                }
              }
            }
          ]
        }
      }
    }
  end

  describe '#deep_locate' do
    subject(:instance) { hash.with_indifferent_access.extend(described_class) }

    it 'can locate symbolic keys' do
      expect(described_class.deep_locate(:lsr10, instance)).to eq ['lsr10' => { 'gte' => 2014 }]
    end

    it 'can locate string keys' do
      expect(described_class.deep_locate('lsr10', instance)).to eq ['lsr10' => { 'gte' => 2014 }]
    end
  end
end

RSpec.describe Hashie::Extensions::IndifferentAccess do
  class Initializable
    attr_reader :coerced, :value

    def initialize(obj, coerced = nil)
      @coerced = coerced
      @value = obj.class.to_s
    end

    def coerced?
      !@coerced.nil?
    end
  end

  class Coercable < Initializable
    def self.coerce(obj)
      new(obj, true)
    end
  end

  class IndifferentHashWithMergeInitializer < Hash
    include Hashie::Extensions::MergeInitializer
    include Hashie::Extensions::IndifferentAccess

    class << self
      alias build new
    end
  end

  class IndifferentHashWithArrayInitializer < Hash
    include Hashie::Extensions::IndifferentAccess

    class << self
      alias build []
    end
  end

  class IndifferentHashWithTryConvertInitializer < Hash
    include Hashie::Extensions::IndifferentAccess

    class << self
      alias build try_convert
    end
  end

  class CoercableHash < Hash
    include Hashie::Extensions::Coercion
    include Hashie::Extensions::MergeInitializer
  end

  class MashWithIndifferentAccess < Hashie::Mash
    include Hashie::Extensions::IndifferentAccess
  end

  shared_examples_for 'hash with indifferent access' do
    it 'is able to access via string or symbol' do
      indifferent_hash = ActiveSupport::HashWithIndifferentAccess.new(abc: 123)
      h = subject.build(indifferent_hash)
      expect(h[:abc]).to eq 123
      expect(h['abc']).to eq 123
    end

    describe '#values_at' do
      it 'indifferently finds values' do
        indifferent_hash = ActiveSupport::HashWithIndifferentAccess.new(
          :foo => 'bar', 'baz' => 'qux'
        )
        h = subject.build(indifferent_hash)
        expect(h.values_at('foo', :baz)).to eq %w[bar qux]
      end
    end

    describe '#fetch' do
      it 'works like normal fetch, but indifferent' do
        indifferent_hash = ActiveSupport::HashWithIndifferentAccess.new(foo: 'bar')
        h = subject.build(indifferent_hash)
        expect(h.fetch(:foo)).to eq h.fetch('foo')
        expect(h.fetch(:foo)).to eq 'bar'
      end
    end

    describe '#delete' do
      it 'deletes indifferently' do
        indifferent_hash = ActiveSupport::HashWithIndifferentAccess.new(
          :foo => 'bar',
          'baz' => 'qux'
        )
        h = subject.build(indifferent_hash)
        h.delete('foo')
        h.delete(:baz)
        expect(h).to be_empty
      end
    end

    describe '#key?' do
      let(:h) do
        indifferent_hash = ActiveSupport::HashWithIndifferentAccess.new(foo: 'bar')
        subject.build(indifferent_hash)
      end

      it 'finds it indifferently' do
        expect(h).to be_key(:foo)
        expect(h).to be_key('foo')
      end

      %w[include? member? has_key?].each do |key_alias|
        it "is aliased as #{key_alias}" do
          expect(h.send(key_alias.to_sym, :foo)).to be(true)
          expect(h.send(key_alias.to_sym, 'foo')).to be(true)
        end
      end
    end

    describe '#update' do
      let(:h) do
        indifferent_hash = ActiveSupport::HashWithIndifferentAccess.new(foo: 'bar')
        subject.build(indifferent_hash)
      end

      it 'allows keys to be indifferent still' do
        h.update(baz: 'qux')
        expect(h['foo']).to eq 'bar'
        expect(h['baz']).to eq 'qux'
      end

      it 'recursively injects indifference into sub-hashes' do
        h.update(baz: { qux: 'abc' })
        expect(h['baz']['qux']).to eq 'abc'
      end

      it 'does not change the ancestors of the injected object class' do
        h.update(baz: { qux: 'abc' })
        expect({}).not_to be_respond_to(:indifferent_access?)
      end
    end

    describe '#replace' do
      let(:h) do
        indifferent_hash = ActiveSupport::HashWithIndifferentAccess.new(foo: 'bar')
        subject.build(indifferent_hash).replace(bar: 'baz', hi: 'bye')
      end

      it 'returns self' do
        expect(h).to be_a(subject)
      end

      it 'removes old keys' do
        [:foo, 'foo'].each do |k|
          expect(h[k]).to be_nil
          expect(h.key?(k)).to be_falsy
        end
      end

      it 'creates new keys with indifferent access' do
        [:bar, 'bar', :hi, 'hi'].each { |k| expect(h.key?(k)).to be_truthy }
        expect(h[:bar]).to eq 'baz'
        expect(h['bar']).to eq 'baz'
        expect(h[:hi]).to eq 'bye'
        expect(h['hi']).to eq 'bye'
      end
    end

    describe '#try_convert' do
      describe 'with conversion' do
        let(:h) do
          indifferent_hash = ActiveSupport::HashWithIndifferentAccess.new(foo: 'bar')
          subject.try_convert(indifferent_hash)
        end

        it 'is a subject' do
          expect(h).to be_a(subject)
        end
      end

      describe 'without conversion' do
        let(:h) { subject.try_convert('{ :foo => bar }') }

        it 'is nil' do
          expect(h).to be_nil
        end
      end
    end
  end

  describe 'with merge initializer' do
    subject { IndifferentHashWithMergeInitializer }
    it_should_behave_like 'hash with indifferent access'
  end

  describe 'with array initializer' do
    subject { IndifferentHashWithArrayInitializer }
    it_should_behave_like 'hash with indifferent access'
  end

  describe 'with try convert initializer' do
    subject { IndifferentHashWithTryConvertInitializer }
    it_should_behave_like 'hash with indifferent access'
  end

  describe 'with coercion' do
    subject { CoercableHash }

    let(:instance) { subject.new }

    it 'supports coercion for ActiveSupport::HashWithIndifferentAccess' do
      subject.coerce_key :foo, ActiveSupport::HashWithIndifferentAccess.new(Coercable => Coercable)
      instance[:foo] = { 'bar_key' => 'bar_value', 'bar2_key' => 'bar2_value' }
      expect(instance[:foo].keys).to all(be_coerced)
      expect(instance[:foo].values).to all(be_coerced)
      expect(instance[:foo]).to be_a(ActiveSupport::HashWithIndifferentAccess)
    end
  end

  describe 'Mash with indifferent access' do
    it 'is able to be created for a deep nested HashWithIndifferentAccess' do
      indifferent_hash = ActiveSupport::HashWithIndifferentAccess.new(abc: { def: 123 })
      MashWithIndifferentAccess.new(indifferent_hash)
    end
  end

  class DashTestDefaultProc < Hashie::Dash
    property :fields, default: -> { [] }
  end

  describe DashTestDefaultProc do
    it 'as_json behaves correctly with default proc' do
      object = described_class.new
      expect(object.as_json).to be == { 'fields' => [] }
    end
  end
end
