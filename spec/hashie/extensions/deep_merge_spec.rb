require 'spec_helper'

describe Hashie::Extensions::DeepMerge do
  class DeepMergeHash < Hash
    include Hashie::Extensions::DeepMerge
  end

  subject { DeepMergeHash }

  it 'should return initial hash for arguments that are not hash' do
    hash = subject.new.merge(a: 'a')
    expect(hash.deep_merge('abc')).to eq(hash)
  end

  context 'without &block' do
    let(:h1) do
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
    let(:h2) { { a: 1, a1: 1, c: { c1: 2, c2: 'c2', c3: { d2: 'd2' } }, e: { e1: 1 } } }
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
      result = h1.deep_merge(h2)

      expect(result).to eq expected_hash
      expect(h1).to(
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
      expect(h2).to eq(a: 1, a1: 1, c: { c1: 2, c2: 'c2', c3: { d2: 'd2' } }, e: { e1: 1 })
    end

    it 'deep merges another hash in place via bang method' do
      result = h1.deep_merge!(h2)

      expect(result).to eq expected_hash
      expect(h1).to eq expected_hash
    end

    it 'merges new nested hash entries by value, not by reference' do
      h1.deep_merge!(h2)
      expect { h1[:e][:e1] = 'changed' }.not_to(change { h2[:e][:e1] })
    end
  end

  context 'with &block' do
    let(:h1) { subject.new.merge(a: 100, b: 200, c: { c1: 100 }) }
    let(:h2) { { b: 250, c: { c1: 200 } } }
    let(:expected_hash) { { a: 100, b: 450, c: { c1: 300 } } }
    let(:block) { proc { |_, this_val, other_val| this_val + other_val } }

    it 'deep merges two hashes' do
      expect(h1.deep_merge(h2, &block)).to eq expected_hash
    end

    context 'with a custom nested hash factory' do
      let(:preserving_class) do
        Class.new(DeepMergeHash) do
          protected

          def deep_merge_new_hash(source)
            source.dup.clear
          end
        end
      end
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

      it 'keeps plain Hash destinations by default at every new level' do
        result = DeepMergeHash.new.deep_merge(addition)
        expect(result[:branch]).to be_instance_of(Hash)
        expect(result[:branch][:child]).to be_instance_of(Hash)
      end

      %i[deep_merge deep_merge!].each do |operation|
        it "preserves incoming classes and state recursively with #{operation}" do
          receiver = preserving_class.new
          result = receiver.public_send(operation, addition)
          branch = result[:branch]
          expect(branch).to be_instance_of(source_class)
          expect(branch.label).to eq('branch')
          expect(branch[:unknown]).to eq('missing unknown')
          branch['MixedCase'] = 'normalized'
          expect(branch['MIXEDCASE']).to eq('normalized')
          expect(branch.keys).to include('mixedcase')
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
    end

    it 'deep merges another hash in place via bang method' do
      h1.deep_merge!(h2, &block)
      expect(h1).to eq expected_hash
    end
  end

  context 'from extended object' do
    subject { Hash }
    let(:h1) { subject.new.merge(a: 100, c: { c1: 100 }).extend(Hashie::Extensions::DeepMerge) }
    let(:h2) { { b: 250, c: { c1: 200 } } }
    let(:expected_hash) { { a: 100, b: 250, c: { c1: 200 } } }

    it 'does not raise error' do
      expect { h1.deep_merge(h2) } .not_to raise_error
    end

    it 'deep merges two hashes' do
      expect(h1.deep_merge(h2)).to eq expected_hash
    end

    it 'deep merges another hash in place via bang method' do
      h1.deep_merge!(h2)
      expect(h1).to eq expected_hash
    end
  end
end
