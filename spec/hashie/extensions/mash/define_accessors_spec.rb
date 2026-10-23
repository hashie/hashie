# frozen_string_literal: true

require 'spec_helper'

describe Hashie::Extensions::Mash::DefineAccessors do
  let(:args) { [] }

  shared_examples 'class with dynamically defined accessors' do
    it 'does not replace private or protected helpers when their names are read as data' do
      instance[:_deep_update] = 'private data'
      instance[:convert_value] = 'protected data'
      expect(instance._deep_update).to eq('private data')
      expect(instance.convert_value).to eq('protected data')
      expect(subject).to be_private_method_defined(:_deep_update)
      expect(subject).to be_protected_method_defined(:convert_value)
      instance.update(nested: { name: 'Ada' })
      expect(instance.nested.name).to eq('Ada')
    end

    it 'defines reader on demand' do
      expect(subject).not_to be_method_defined(:foo)
      instance.foo
      expect(subject).to be_method_defined(:foo)
    end

    it 'defines writer on demand' do
      expect(subject).not_to be_method_defined(:foo=)
      instance.foo = :bar
      expect(subject).to be_method_defined(:foo=)
    end

    it 'defines predicate on demand' do
      expect(subject).not_to be_method_defined(:foo?)
      instance.foo?
      expect(subject).to be_method_defined(:foo?)
    end

    it 'defines initializing reader on demand' do
      expect(subject).not_to be_method_defined(:foo!)
      instance.foo!
      expect(subject).to be_method_defined(:foo!)
    end

    it 'defines underbang reader on demand' do
      expect(subject).not_to be_method_defined(:foo_)
      instance.foo_
      expect(subject).to be_method_defined(:foo_)
    end

    context 'when initializing from another hash' do
      let(:args) { [{ foo: :bar }] }

      it 'does not define any accessors' do
        expect(subject).not_to be_method_defined(:foo)
        expect(subject).not_to be_method_defined(:foo=)
        expect(subject).not_to be_method_defined(:foo?)
        expect(subject).not_to be_method_defined(:foo!)
        expect(subject).not_to be_method_defined(:foo_)
        expect(instance.foo).to eq :bar
      end
    end
  end

  context 'when included in Mash subclass' do
    subject { Class.new(Hashie::Mash) { include Hashie::Extensions::Mash::DefineAccessors } }

    let(:instance) { subject.new(*args) }

    describe 'this subclass' do
      it_behaves_like 'class with dynamically defined accessors'

      describe '#dup' do
        %w[regular_default regular_default_proc].each do |key|
          context "after reading the #{key} data accessor" do
            let(:args) { [{ key => 'data' }] }

            [nil, :fallback].each do |default|
              it "preserves #{default.inspect} as the default" do
                instance.default = default
                expect(instance.public_send(key)).to eq 'data'

                copy = instance.dup

                expect(copy).to be_an_instance_of(subject)
                expect(copy[key]).to eq 'data'
                expect(copy.default).to eq default
                expect(copy['missing']).to eq default
              end
            end

            it 'preserves the default proc and applies it to the copy' do
              instance.default_proc = proc { |hash, name| hash[name] = [] }
              expect(instance.public_send(key)).to eq 'data'

              copy = instance.dup

              expect(copy[key]).to eq 'data'
              expect(copy.default_proc).to equal(instance.default_proc)
              expect(copy['missing']).to eq []
              expect(instance).not_to have_key('missing')
            end
          end
        end
      end

      describe 'when accessors are overridden in class' do
        before do
          subject.class_eval do
            def foo
              if self[:foo] == 1
                super
              else
                :bar
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
    subject { instance.singleton_class }

    let(:instance) { Hashie::Mash.new(*args).with_accessors! }

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
