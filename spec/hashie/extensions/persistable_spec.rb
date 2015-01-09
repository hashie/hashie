require 'tempfile'

module Hashie
  module Extensions
    RSpec.describe Persistable do
      shared_examples 'loads YAML' do | test_class |
        describe '.load' do
          subject(:hash) { test_class.load('spec/fixtures/persistable/hello_world.yaml') }
          it 'instantiates a instance from a YAML file' do
            expect(hash).to be_a_kind_of ::Hash
            expect(hash).to eq(
              'foo' => 'bar',
              'msg' => 'Hello, world!'
            )
          end

          it 'remembers the filename' do
            expect(hash.persistable_file).to eq(Pathname('spec/fixtures/persistable/hello_world.yaml'))
          end
        end
      end

      shared_examples 'saves YAML' do | test_class |
        describe '#save' do
          let(:obj) do
            test_class.new(
              'foo' => 'bar!',
              'msg' => 'saved!'
            )
          end

          it 'raises an error if persistable_file is not set' do
            expect { obj.save }.to raise_error(ArgumentError, /cannot save unless persistable_file is set/i)
          end

          it 'saves to persistable_file' do
            tmpfile = Tempfile.new(['hash', '.yaml'])
            obj.persistable_file = tmpfile
            expect(obj.save).to eq(Pathname(tmpfile))
            expect(test_class.load(tmpfile)).to eq(obj)
          end

          it 'changes and saves to persistable_file (passed as an argument)' do
            tmpfile = Tempfile.new(['hash', '.yaml'])
            expect(obj.save(tmpfile)).to eq(Pathname(tmpfile))
            expect(obj.persistable_file).to eq(Pathname(tmpfile))
            expect(test_class.load(tmpfile)).to eq(obj)
          end
        end

        describe '#[]=' do
          context 'with autosave enabled'
          pending 'autosaves'
          context 'without autosave enabled' do
            pending 'does not autosave'
          end
        end
      end

      context 'with Hash' do
        class MyHash < ::Hash
          include Hashie::Extensions::MergeInitializer
          include Hashie::Extensions::Persistable
        end

        include_examples 'loads YAML', MyHash
        include_examples 'saves YAML', MyHash
      end

      context 'with Hashie::Hash' do
        class MyHashieHash < Hashie::Hash
          include Hashie::Extensions::MergeInitializer
          include Hashie::Extensions::Persistable
        end

        include_examples 'loads YAML', MyHashieHash
        include_examples 'saves YAML', MyHashieHash
      end

      context 'with Hashie::Mash' do
        class MyHashieMash < Hashie::Mash
          include Hashie::Extensions::Persistable
        end

        include_examples 'loads YAML', MyHashieMash
        include_examples 'saves YAML', MyHashieMash
      end

      context 'with Hashie::Dash' do
        class MyHashieDash < Hashie::Dash
          include Hashie::Extensions::Persistable
          property 'foo'
          property 'msg'
        end

        include_examples 'loads YAML', MyHashieDash
        include_examples 'saves YAML', MyHashieDash
      end
    end
  end
end
