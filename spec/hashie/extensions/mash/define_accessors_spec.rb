require 'spec_helper'

describe Hashie::Extensions::Mash::DefineAccessors do
  let(:args) { [] }

  shared_examples 'class with dynamically defined accessors' do
    it 'defines reader on demand' do
      expect(subject.method_defined?(:foo)).to be_falsey
      instance.foo
      expect(subject.method_defined?(:foo)).to be_truthy
    end

    it 'defines writer on demand' do
      expect(subject.method_defined?(:foo=)).to be_falsey
      instance.foo = :bar
      expect(subject.method_defined?(:foo=)).to be_truthy
    end

    it 'defines predicate on demand' do
      expect(subject.method_defined?(:foo?)).to be_falsey
      instance.foo?
      expect(subject.method_defined?(:foo?)).to be_truthy
    end

    it 'defines initializing reader on demand' do
      expect(subject.method_defined?(:foo!)).to be_falsey
      instance.foo!
      expect(subject.method_defined?(:foo!)).to be_truthy
    end

    it 'defines underbang reader on demand' do
      expect(subject.method_defined?(:foo_)).to be_falsey
      instance.foo_
      expect(subject.method_defined?(:foo_)).to be_truthy
    end

    context 'when initializing from another hash' do
      let(:args) { [{ foo: :bar }] }

      it 'does not define any accessors' do
        expect(subject.method_defined?(:foo)).to be_falsey
        expect(subject.method_defined?(:foo=)).to be_falsey
        expect(subject.method_defined?(:foo?)).to be_falsey
        expect(subject.method_defined?(:foo!)).to be_falsey
        expect(subject.method_defined?(:foo_)).to be_falsey
        expect(instance.foo).to eq :bar
      end
    end
  end

  context 'when included in Mash subclass' do
    subject { Class.new(Hashie::Mash) { include Hashie::Extensions::Mash::DefineAccessors } }
    let(:instance) { subject.new(*args) }

    describe 'this subclass' do
      it_behaves_like 'class with dynamically defined accessors'

      describe 'when accessors are overridden in class' do
        before do
          subject.class_eval do
            def foo
              if self[:foo] != 1
                :bar
              else
                super
              end
            end
          end
        end

        it 'allows to call super' do
          expect(instance.foo).to eq :bar
          instance.foo = 2
          expect(instance.foo).to eq :bar
          instance.foo = 1
          expect(instance.foo).to eq 1
        end
      end
    end
  end

  context 'when Mash instance is extended' do
    let(:instance) { Hashie::Mash.new(*args).with_accessors! }
    subject { instance.singleton_class }

    describe 'its singleton class' do
      it_behaves_like 'class with dynamically defined accessors'
    end
  end

  context 'when accessing a key that literally matches the generated method name' do
    subject { Class.new(Hashie::Mash) { include Hashie::Extensions::Mash::DefineAccessors } }

    it 'reuses the already-defined writer for a literal = key' do
      instance = subject.new('foo=' => 'literal')
      instance.foo = 'ignored'
      expect(instance['foo=']).to eq 'literal'
      instance.foo = 'ignored again'
      expect(instance['foo=']).to eq 'literal'
    end

    it 'reuses the already-defined predicate for a literal ? key' do
      instance = subject.new('foo?' => 'literal')
      expect(instance.foo?).to eq 'literal'
      expect(instance.foo?).to eq 'literal'
    end

    it 'reuses the already-defined initializing reader for a literal ! key' do
      instance = subject.new('foo!' => 'literal')
      expect(instance.foo!).to eq 'literal'
      expect(instance.foo!).to eq 'literal'
    end

    it 'reuses the already-defined underbang reader for a literal _ key' do
      instance = subject.new('foo_' => 'literal')
      expect(instance.foo_).to be_nil
      expect(instance.foo_).to be_nil
    end
  end
end
