# frozen_string_literal: true

require 'spec_helper'

describe Hashie::Extensions::BlockAccess do
  let(:hash_class) do
    Class.new(Hash) do
      include Hashie::Extensions::MethodAccess
      include Hashie::Extensions::BlockAccess
    end
  end

  let(:mash_class) do
    Class.new(Hashie::Mash) do
      include Hashie::Extensions::BlockAccess
    end
  end

  let(:dash_class) do
    Class.new(Hashie::Dash) do
      include Hashie::Extensions::BlockAccess

      property :author
      property :name
    end
  end

  shared_examples 'block access' do
    subject(:hash) { klass.new }

    it 'creates and returns a nested instance of the same class' do
      result = hash.author { |author| author.name = 'Michael Bleigh' }

      expect(result).to be_an_instance_of(klass)
      expect(result).to equal(hash.author)
      expect(hash.author.name).to eq 'Michael Bleigh'
    end

    it 'reuses existing children on subsequent calls' do
      hash.author { |author| author.name = 'Michael Bleigh' }
      original = hash.author
      result = hash.author { |author| author.name = 'Bob' }

      expect(result).to equal(original)
      expect(hash.author.name).to eq 'Bob'
    end

    it 'builds multiple levels' do
      hash.author do |author|
        author.author { |nested| nested.name = 'Bob' }
      end

      expect(hash.author.author.name).to eq 'Bob'
    end

    it 'supports bracket access' do
      result = hash[key] { |author| author.name = 'Bob' }

      expect(result).to equal(hash[key])
      expect(result.name).to eq 'Bob'
    end

    it 'preserves normal reads and writes' do
      hash.name = 'Bob'

      expect(hash.name).to eq 'Bob'
      expect(hash[key]).to be_nil
    end

    [nil, false, 42, 'Bob', []].each do |value|
      it "rejects an existing #{value.inspect} instead of overwriting it" do
        hash[key] = value

        expect { hash.author {} }.to raise_error(TypeError)
        expect(hash[key]).to eq value
      end
    end

    it 'propagates exceptions from the block' do
      expect { hash.author { raise 'block failure' } }
        .to raise_error(RuntimeError, 'block failure')
    end

    it 'does not intercept real methods taking blocks' do
      hash.name = 'Bob'

      expect(hash.map { |_, value| value }).to eq ['Bob']
    end
  end

  context 'with a Hash subclass using MethodAccess' do
    let(:klass) { hash_class }
    let(:key) { 'author' }

    include_examples 'block access'
  end

  context 'with a Mash subclass' do
    let(:klass) { mash_class }
    let(:key) { 'author' }

    include_examples 'block access'
  end

  context 'with a Dash subclass' do
    let(:klass) { dash_class }
    let(:key) { :author }

    include_examples 'block access'

    it 'rejects undeclared properties' do
      expect { klass.new.unknown {} }.to raise_error(NoMethodError)
    end
  end

  context 'with a plain Hash subclass' do
    subject(:hash) do
      Class.new(Hash) do
        include Hashie::Extensions::BlockAccess
      end.new
    end

    it 'does not require method readers or writers to build a child' do
      result = hash.author { |author| author['name'] = 'Bob' }

      expect(result).to equal(hash['author'])
      expect(hash['author']['name']).to eq 'Bob'
    end

    it 'still raises for unknown methods without a block' do
      expect { hash.unknown }.to raise_error(NoMethodError)
    end
  end

  context 'with named children' do
    subject(:hash) { hash_class.new }

    it 'builds distinct children using the optional key argument' do
      first = hash.test(:one) { |one| one.foo = 'bar' }
      second = hash.test(:two) { |two| two.hurp = 'derp' }

      expect(first).to equal(hash.test[:one])
      expect(second).to equal(hash.test[:two])
      expect(hash.test.one.foo).to eq 'bar'
      expect(hash.test.two.hurp).to eq 'derp'
    end

    it 'reuses an existing named child' do
      hash.test(:one) { |one| one.foo = 'bar' }
      original = hash.test[:one]

      expect(hash.test(:one) { |one| one.foo = 'baz' }).to equal(original)
      expect(original.foo).to eq 'baz'
    end

    it 'rejects too many arguments before creating a child' do
      expect { hash.test(:one, :two) {} }.to raise_error(ArgumentError)
      expect(hash).to be_empty
    end

    it 'rejects non-hash named children without overwriting them' do
      hash.test { |test| test[:one] = false }

      expect { hash.test(:one) {} }.to raise_error(TypeError)
      expect(hash.test[:one]).to eq false
    end
  end

  it 'uses an existing symbol key instead of creating a string key' do
    hash = hash_class.new
    child = hash_class.new
    hash[:author] = child

    expect(hash.author { |author| author.name = 'Bob' }).to equal(child)
    expect(hash.keys).to eq [:author]
  end

  it 'honors custom key conversion' do
    klass = Class.new(hash_class) do
      def convert_key(key)
        key.to_sym
      end
    end
    hash = klass.new
    hash.author { |author| author.name = 'Bob' }

    expect(hash.keys).to eq [:author]
    expect(hash.author[:name]).to eq 'Bob'
  end

  it 'yields existing ordinary hashes without converting or copying them' do
    hash = hash_class.new
    child = {}
    hash['author'] = child

    expect(hash.author { |author| author['name'] = 'Bob' }).to equal(child)
    expect(child).to eq('name' => 'Bob')
  end

  it 'does not use a default value as a missing child' do
    hash = hash_class.new(:fallback)
    hash.author { |author| author.name = 'Bob' }

    expect(hash.author.name).to eq 'Bob'
    expect(hash['missing']).to eq :fallback
  end

  it 'does not invoke a default proc when creating a missing child' do
    hash = hash_class.new { raise 'default failure' }
    hash.author { |author| author.name = 'Bob' }

    expect(hash.author.name).to eq 'Bob'
    expect { hash['missing'] }.to raise_error(RuntimeError, 'default failure')
  end

  it 'preserves Mash suffix behavior' do
    hash = mash_class.new
    expect(hash.unknown?).to eq false
    expect(hash.author!).to be_an_instance_of(mash_class)
    expect(hash.temporary_).to be_an_instance_of(mash_class)
    expect(hash).not_to have_key('temporary')
  end

  it 'does not enable block construction on an ordinary Mash' do
    mash = Hashie::Mash.new
    expect(mash.author { |author| author }).to be_nil
    expect(mash).to be_empty
  end

  it 'does not advertise unknown readers just because a block can build them' do
    hash = hash_class.new
    expect(hash).not_to respond_to(:author)
    hash.author {}
    expect(hash).to respond_to(:author)
  end

  it 'preserves constructor validations when building children' do
    klass = Class.new(Hashie::Dash) do
      include Hashie::Extensions::BlockAccess

      property :name, required: true
      property :author
    end
    hash = klass.new(name: 'Bob')

    expect { hash.author {} }.to raise_error(ArgumentError)
    expect(hash).not_to have_key(:author)
  end

  it 'preserves errors when writing to a frozen hash' do
    hash = hash_class.new.freeze

    expect { hash.author {} }.to raise_error(FrozenError)
    expect(hash).to be_empty
  end
end
