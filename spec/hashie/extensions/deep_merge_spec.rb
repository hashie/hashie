# frozen_string_literal: true

require 'spec_helper'

describe Hashie::Extensions::DeepMerge do
  class DeepMergeHash < Hash
    include Hashie::Extensions::DeepMerge
  end

  subject { DeepMergeHash }

  it 'returns initial hash for arguments that are not hash' do
    hash = subject.new.merge(a: 'a')
    expect(hash.deep_merge('abc')).to eq(hash)
  end

  context 'value copying' do
    let(:value) do
      Class.new do
        def dup
          raise 'unexpected dup'
        end

        def deep_dup
          raise 'unexpected deep_dup'
        end
      end.new
    end

    it 'retains arbitrary objects on both sides, including inside arrays and hashes' do
      receiver = subject[existing: [value, { nested: value }]]
      incoming = { added: [value, { nested: value }] }
      result = receiver.deep_merge(incoming)

      expect(result[:existing].first).to equal(value)
      expect(result[:existing].last[:nested]).to equal(value)
      expect(result[:added].first).to equal(value)
      expect(result[:added].last[:nested]).to equal(value)
    end

    it 'recursively copies receiver containers and strings without changing their types' do
      array_class = Class.new(Array)
      original = subject[items: array_class[[{ text: +'original' }]]]
      result = original.deep_merge({})

      expect(result).to be_instance_of(DeepMergeHash)
      expect(result[:items]).to be_instance_of(array_class)
      result[:items].first.first[:text].replace('changed')
      result[:items].first << :extra
      result[:items] << :extra
      expect(original[:items]).to eq([[{ text: 'original' }]])
    end

    %i[deep_merge deep_merge!].each do |operation|
      it "copies incoming containers and strings with #{operation}, retaining rich objects" do
        incoming = { items: [[{ text: +'original', object: value }]], text: +'original' }
        receiver = subject.new
        result = receiver.public_send(operation, incoming)

        expect(result[:items].first.first[:object]).to equal(value)
        result[:items].first.first[:text].replace('changed')
        result[:items].first << :extra
        result[:items] << :extra
        result[:text].replace('changed')
        expect(incoming).to eq(items: [[{ text: 'original', object: value }]], text: 'original')
        expect(receiver).to be_empty if operation == :deep_merge
        expect(result).to equal(receiver) if operation == :deep_merge!
      end
    end

    it 'leaves existing values in place for deep_merge!' do
      array = [value, +'original']
      receiver = subject[items: array]

      expect(receiver.deep_merge!({})[:items]).to equal(array)
      expect(receiver[:items].first).to equal(value)
    end

    it 'passes original incoming conflict values and retains block result identity' do
      old = [value]
      incoming = [value]
      replacement = [value]
      receiver = subject[items: old]
      result = receiver.deep_merge(items: incoming) do |key, left, right|
        expect(key).to eq(:items)
        expect(left).to eq(old)
        expect(left).not_to equal(old)
        expect(right).to equal(incoming)
        replacement
      end

      expect(result[:items]).to equal(replacement)
    end
  end

  context 'without &block' do
    let(:receiver) do
      subject.new.merge(
        a: 'a',
        a1: 42,
        b: 'b',
        c: { c1: 'c1', c2: { a: 'b' }, c3: { d1: 'd1' } },
        d: nil,
        d1: false,
        d2: true,
        d3: unbound_method,
        d4: Complex(1),
        d5: Rational(1)
      )
    end
    let(:incoming) { { a: 1, a1: 1, c: { c1: 2, c2: 'c2', c3: { d2: 'd2' } }, e: { e1: 1 } } }
    let(:unbound_method) { method(:puts) }
    let(:expected_hash) do
      {
        a: 1,
        a1: 1,
        b: 'b',
        c: { c1: 2, c2: 'c2', c3: { d1: 'd1', d2: 'd2' } },
        d: nil,
        d1: false,
        d2: true,
        d3: unbound_method,
        d4: Complex(1),
        d5: Rational(1),
        e: { e1: 1 }
      }
    end

    it 'deep merges two hashes without modifying them' do
      result = receiver.deep_merge(incoming)

      expect(result).to eq expected_hash
      expect(receiver).to(
        eq(
          a: 'a',
          a1: 42,
          b: 'b',
          c: { c1: 'c1', c2: { a: 'b' }, c3: { d1: 'd1' } },
          d: nil,
          d1: false,
          d2: true,
          d3: unbound_method,
          d4: Complex(1),
          d5: Rational(1)
        )
      )
      expect(incoming).to eq(a: 1, a1: 1, c: { c1: 2, c2: 'c2', c3: { d2: 'd2' } }, e: { e1: 1 })
    end

    it 'deep merges another hash in place via bang method' do
      result = receiver.deep_merge!(incoming)

      expect(result).to eq expected_hash
      expect(receiver).to eq expected_hash
    end

    it 'merges new nested hash entries by value, not by reference' do
      receiver.deep_merge!(incoming)
      expect { receiver[:e][:e1] = 'changed' }.not_to(change { incoming[:e][:e1] })
    end
  end

  context 'with &block' do
    let(:receiver) { subject.new.merge(a: 100, b: 200, c: { c1: 100 }) }
    let(:incoming) { { b: 250, c: { c1: 200 } } }
    let(:expected_hash) { { a: 100, b: 450, c: { c1: 300 } } }
    let(:block) { proc { |_, this_val, other_val| this_val + other_val } }

    it 'deep merges two hashes' do
      expect(receiver.deep_merge(incoming, &block)).to eq expected_hash
    end

    context 'preserving incoming hash types' do
      let(:preserving_class) { DeepMergeHash }
      let(:source_class) do
        Class.new(Hash) do
          attr_reader :label

          def initialize(label)
            @label = label
            super() { |_, key| "missing #{key}" }
          end

          def [](key)
            super(key.is_a?(String) ? key.downcase : key)
          end

          def []=(key, value)
            super(key.is_a?(String) ? key.downcase : key, value)
          end
        end
      end
      let(:addition) do
        leaf = source_class.new('leaf')
        leaf[:value] = 2
        branch = source_class.new('branch')
        branch[:child] = leaf
        { branch: branch }
      end

      %i[deep_merge deep_merge!].each do |operation|
        it "preserves incoming classes and state recursively by default with #{operation}" do
          receiver = preserving_class.new
          result = receiver.public_send(operation, addition)
          branch = result[:branch]
          expect(branch).to be_instance_of(source_class)
          expect(branch.label).to eq('branch')
          expect(branch[:unknown]).to eq('missing unknown')
          branch['Name'] = 'normalized'
          expect(branch['NAME']).to eq('normalized')
          expect(branch.keys).to include('name')
          expect(branch[:child]).to be_instance_of(source_class)
          expect(branch[:child].label).to eq('leaf')
          expect(branch).not_to equal(addition[:branch])
          expect(branch[:child]).not_to equal(addition[:branch][:child])
          branch[:child][:value] = 3
          expect(addition[:branch][:child][:value]).to eq(2)
          expect(receiver).to be_empty if operation == :deep_merge
          expect(result).to equal(receiver) if operation == :deep_merge!
        end
      end

      it 'retains existing destination types and passes the conflict block through recursion' do
        receiver = preserving_class.new
        receiver[:branch] = { child: { value: 10 } }
        result = receiver.deep_merge(addition) { |_, old, incoming| old + incoming }
        expect(result[:branch]).to be_instance_of(Hash)
        expect(result[:branch][:child]).to be_instance_of(Hash)
        expect(result[:branch][:child][:value]).to eq(12)
        expect(receiver[:branch][:child][:value]).to eq(10)
      end

      it 'preserves required-property Dashes without calling an empty constructor' do
        dash = Class.new(Hashie::Dash) { property :name, required: true }
        source = dash.new(name: 'Ada')
        result = preserving_class.new.deep_merge(person: source)
        expect(result[:person]).to be_instance_of(dash)
        expect(result[:person].name).to eq('Ada')
        expect(source.name).to eq('Ada')
      end

      it 'keeps keyword-style input hashes as merge data rather than introducing options' do
        result = preserving_class.new.deep_merge(keep_hash_subclasses: { value: 1 })
        expect(result).to eq(keep_hash_subclasses: { value: 1 })
      end

      it 'preserves incoming hash types inside nested replacement arrays' do
        %i[deep_merge deep_merge!].each do |operation|
          result = preserving_class.new.public_send(operation, items: [[addition[:branch]]])
          branch = result[:items].first.first
          expect(branch).to be_instance_of(source_class)
          expect(branch.label).to eq('branch')
          expect(branch[:child]).to be_instance_of(source_class)
          expect(branch[:child]).not_to equal(addition[:branch][:child])
        end
        result = DeepMergeHash.new.deep_merge(items: [addition[:branch]])
        expect(result[:items].first).to be_instance_of(source_class)
      end
    end

    it 'deep merges another hash in place via bang method' do
      receiver.deep_merge!(incoming, &block)
      expect(receiver).to eq expected_hash
    end
  end

  context 'from extended object' do
    subject { Hash }

    let(:receiver) { subject.new.merge(a: 100, c: { c1: 100 }).extend(described_class) }
    let(:incoming) { { b: 250, c: { c1: 200 } } }
    let(:expected_hash) { { a: 100, b: 250, c: { c1: 200 } } }

    it 'does not raise error' do
      expect { receiver.deep_merge(incoming) }.not_to raise_error
    end

    it 'deep merges two hashes' do
      expect(receiver.deep_merge(incoming)).to eq expected_hash
    end

    it 'deep merges another hash in place via bang method' do
      receiver.deep_merge!(incoming)
      expect(receiver).to eq expected_hash
    end
  end
end
