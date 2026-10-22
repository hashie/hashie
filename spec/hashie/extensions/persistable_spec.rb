# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

module PersistenceFixtures
  class Hash < ::Hash
    include Hashie::Extensions::MergeInitializer
    include Hashie::Extensions::Persistable
  end

  class Mash < Hashie::Mash
    include Hashie::Extensions::Persistable
  end

  class Dash < Hashie::Dash
    include Hashie::Extensions::Persistable
    property :name, required: true
    property :child
  end

  class Trash < Hashie::Trash
    include Hashie::Extensions::Persistable
    property :name, required: true, from: :full_name
    property :child
  end
end

describe Hashie::Extensions::Persistable do
  around do |example|
    Dir.mktmpdir('hashie-persistence') do |directory|
      @directory = directory
      example.run
    end
  end

  let(:path) { File.join(@directory, 'data.yaml') }
  let(:other_path) { File.join(@directory, 'other.yaml') }

  [PersistenceFixtures::Hash, PersistenceFixtures::Mash,
   PersistenceFixtures::Dash, PersistenceFixtures::Trash].each do |klass|
    context "with #{klass}" do
      let(:source) { klass.new(name: 'parent', child: { name: 'child', items: [nil, false, 42] }) }

      it 'saves, loads, modifies, and saves back to its source file' do
        expect(source.save(path)).to eq path
        recovered = klass.load(path)
        expect(recovered).to be_an_instance_of(klass)
        expect(recovered).to eq source
        expect(recovered.persistable_path).to eq path
        key = recovered.keys.find { |candidate| candidate.to_s == 'name' }
        recovered[key] = 'changed'
        expect(recovered.save).to eq path
        expect(klass.load(path)[key]).to eq 'changed'
      end

      it 'writes plain YAML without Ruby class tags' do
        source.save(path)
        expect(File.read(path)).not_to include('!ruby/')
        expect(Psych.safe_load(File.read(path), permitted_classes: [Symbol])).to be_a(::Hash)
      end
    end
  end

  let(:source) { PersistenceFixtures::Hash.new(name: 'parent') }

  it 'requires a path before the first save' do
    expect { source.save }.to raise_error(ArgumentError, 'a persistence path is required')
  end

  it 'accepts Pathname paths and remembers an absolute path' do
    source.save(Pathname.new(path))
    expect(source.persistable_path).to eq File.expand_path(path)
  end

  it 'changes the remembered path after a successful save' do
    source.save(path)
    source.save(other_path)
    expect(source.persistable_path).to eq other_path
    expect(File.read(other_path)).to eq File.read(path)
  end

  it 'preserves contents and the remembered path on a write failure' do
    source.save(path)
    original = File.read(path)
    allow(File).to receive(:rename).and_raise(Errno::EACCES)

    expect { source.save(other_path) }.to raise_error(Errno::EACCES)
    expect(source.persistable_path).to eq path
    expect(File.read(path)).to eq original
    expect(File).not_to exist(other_path)
    expect(Dir.children(@directory)).to eq ['data.yaml']
  end

  it 'preserves an existing destination on replacement failure' do
    source.save(path)
    File.write(other_path, 'original contents')
    allow(File).to receive(:rename).and_raise(Errno::EACCES)

    expect { source.save(other_path) }.to raise_error(Errno::EACCES)
    expect(File.read(other_path)).to eq 'original contents'
    expect(source.persistable_path).to eq path
  end

  it 'rejects unsupported values before touching the destination' do
    source.save(path)
    original = File.read(path)
    source[:object] = Object.new

    expect { source.save }.to raise_error(TypeError)
    expect(File.read(path)).to eq original
  end

  it 'preserves destination permissions' do
    source.save(path)
    File.chmod(0o640, path)
    source.save
    expect(File.stat(path).mode & 0o777).to eq 0o640
  end

  it 'saves shared values without introducing YAML aliases' do
    shared = 'shared'
    source[:first] = shared
    source[:second] = shared
    source.save(path)

    expect(PersistenceFixtures::Hash.load(path)).to eq source
  end

  it 'rejects cyclic values without touching the destination' do
    source.save(path)
    original = File.read(path)
    source[:cycle] = source

    expect { source.save }.to raise_error(ArgumentError, 'cannot persist cyclic data')
    expect(File.read(path)).to eq original
  end

  it 'rejects non-string and non-symbol keys' do
    source[Object.new] = 'value'
    expect { source.save(path) }.to raise_error(TypeError)
    expect(File).not_to exist(path)
  end

  it 'rejects malformed YAML' do
    File.write(path, 'name: [')
    expect { PersistenceFixtures::Hash.load(path) }.to raise_error(Psych::SyntaxError)
  end

  ['---', '- item', '42'].each do |yaml|
    it "rejects non-hash YAML #{yaml.inspect}" do
      File.write(path, yaml)
      expect { PersistenceFixtures::Hash.load(path) }.to raise_error(TypeError)
    end
  end

  it 'rejects Ruby object tags' do
    File.write(path, '--- !ruby/object:Object {}')
    expect { PersistenceFixtures::Hash.load(path) }.to raise_error(Psych::DisallowedClass)
  end

  it 'does not evaluate ERB' do
    File.write(path, 'name: <%= raise "evaluated" %>')
    expect(PersistenceFixtures::Hash.load(path)[:name]).to be_nil
    expect(PersistenceFixtures::Hash.load(path)['name']).to include('<%=')
  end

  it 'propagates missing-file errors' do
    expect { PersistenceFixtures::Hash.load(path) }.to raise_error(Errno::ENOENT)
  end

  it 'validates required Dash properties when loading' do
    File.write(path, Psych.dump(child: {}))
    expect { PersistenceFixtures::Dash.load(path) }.to raise_error(ArgumentError)
  end

  it 'preserves Trash translation when loading' do
    File.write(path, Psych.dump(full_name: 'translated'))
    expect(PersistenceFixtures::Trash.load(path).name).to eq 'translated'
  end

  it 'does not change ordinary Mash loading' do
    expect(Hashie::Mash.method(:load).owner).to eq Hashie::Mash.singleton_class
  end
end
