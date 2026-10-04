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
end
