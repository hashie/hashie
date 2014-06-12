require 'spec_helper'
require 'delegate'

describe Hashie::Mash do
  subject { Hashie::Mash.new }

  it 'inherits from Hash' do
    expect(subject.is_a?(Hash)).to be true
  end

  it 'sets hash values through method= calls' do
    subject.test = 'abc'
    expect(subject['test']).to eq 'abc'
  end

  it 'retrieves set values through method calls' do
    subject['test'] = 'abc'
    expect(subject.test).to eq 'abc'
  end

  it 'retrieves set values through blocks' do
    subject['test'] = 'abc'
    value = nil
    subject.[]('test') { |v| value = v }
    expect(value).to eq 'abc'
  end

  it 'retrieves set values through blocks with method calls' do
    subject['test'] = 'abc'
    value = nil
    subject.test { |v| value = v }
    expect(value).to eq 'abc'
  end

  it 'tests for already set values when passed a ? method' do
    expect(subject.test?).to be false
    subject.test = 'abc'
    expect(subject.test?).to be true
  end

  it 'returns false on a ? method if a value has been set to nil or false' do
    subject.test = nil
    expect(subject).not_to be_test
    subject.test = false
    expect(subject).not_to be_test
  end

  it 'makes all [] and []= into strings for consistency' do
    subject['abc'] = 123
    expect(subject.key?('abc')).to be true
    expect(subject['abc']).to eq 123
  end

  it 'has a to_s that is identical to its inspect' do
    subject.abc = 123
    expect(subject.to_s).to eq subject.inspect
  end

  it 'returns nil instead of raising an error for attribute-esque method calls' do
    expect(subject.abc).to be_nil
  end

  it 'returns the default value if set like Hash' do
    subject.default = 123
    expect(subject.abc).to eq 123
  end

  it 'gracefully handles being accessed with arguments' do
    expect(subject.abc('foobar')).to eq nil
    subject.abc = 123
    expect(subject.abc('foobar')).to eq 123
  end

  it 'returns a Hashie::Mash when passed a bang method to a non-existenct key' do
    expect(subject.abc!.is_a?(Hashie::Mash)).to be true
  end

  it 'returns the existing value when passed a bang method for an existing key' do
    subject.name = 'Bob'
    expect(subject.name!).to eq 'Bob'
  end

  it 'returns a Hashie::Mash when passed an under bang method to a non-existenct key' do
    expect(subject.abc_.is_a?(Hashie::Mash)).to be true
  end

  it 'returns the existing value when passed an under bang method for an existing key' do
    subject.name = 'Bob'
    expect(subject.name_).to eq 'Bob'
  end

  it '#initializing_reader returns a Hashie::Mash when passed a non-existent key' do
    expect(subject.initializing_reader(:abc).is_a?(Hashie::Mash)).to be true
  end

  it 'allows for multi-level assignment through bang methods' do
    subject.author!.name = 'Michael Bleigh'
    expect(subject.author).to eq Hashie::Mash.new(name: 'Michael Bleigh')
    subject.author!.website!.url = 'http://www.mbleigh.com/'
    expect(subject.author.website).to eq Hashie::Mash.new(url: 'http://www.mbleigh.com/')
  end

  it 'allows for multi-level under bang testing' do
    expect(subject.author_.website_.url).to be_nil
    expect(subject.author_.website_.url?).to eq false
    expect(subject.author).to be_nil
  end

  it 'does not call super if id is not a key' do
    expect(subject.id).to eq nil
  end

  it 'returns the value if id is a key' do
    subject.id = 'Steve'
    expect(subject.id).to eq 'Steve'
  end

  it 'does not call super if type is not a key' do
    expect(subject.type).to eq nil
  end

  it 'returns the value if type is a key' do
    subject.type = 'Steve'
    expect(subject.type).to eq 'Steve'
  end

  context 'updating' do
    subject do
      described_class.new(
        first_name: 'Michael',
        last_name: 'Bleigh',
        details: {
          email: 'michael@asf.com',
          address: 'Nowhere road'
        })
    end

    describe '#deep_update' do
      it 'recursively Hashie::Mash Hashie::Mashes and hashes together' do
        subject.deep_update(details: { email: 'michael@intridea.com', city: 'Imagineton' })
        expect(subject.first_name).to eq 'Michael'
        expect(subject.details.email).to eq 'michael@intridea.com'
        expect(subject.details.address).to eq 'Nowhere road'
        expect(subject.details.city).to eq 'Imagineton'
      end

      it 'converts values only once' do
        class ConvertedMash < Hashie::Mash
        end

        rhs = ConvertedMash.new(email: 'foo@bar.com')
        expect(subject).to receive(:convert_value).exactly(1).times
        subject.deep_update(rhs)
      end

      it 'makes #update deep by default' do
        expect(subject.update(details: { address: 'Fake street' })).to eql(subject)
        expect(subject.details.address).to eq 'Fake street'
        expect(subject.details.email).to eq 'michael@asf.com'
      end

      it 'clones before a #deep_merge' do
        duped = subject.deep_merge(details: { address: 'Fake street' })
        expect(duped).not_to eql(subject)
        expect(duped.details.address).to eq 'Fake street'
        expect(subject.details.address).to eq 'Nowhere road'
        expect(duped.details.email).to eq 'michael@asf.com'
      end

      it 'default #merge is deep' do
        duped = subject.merge(details: { email: 'michael@intridea.com' })
        expect(duped).not_to eql(subject)
        expect(duped.details.email).to eq 'michael@intridea.com'
        expect(duped.details.address).to eq 'Nowhere road'
      end

      # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-update
      it 'accepts a block' do
        duped = subject.merge(details: { address: 'Pasadena CA' }) { |key, oldv, newv| [oldv, newv].join(', ') }
        expect(duped.details.address).to eq 'Nowhere road, Pasadena CA'
      end
    end

    describe 'shallow update' do
      it 'shallowly Hashie::Mash Hashie::Mashes and hashes together' do
        expect(subject.shallow_update(details: {  email: 'michael@intridea.com',
                                                  city: 'Imagineton' })).to eql(subject)

        expect(subject.first_name).to eq 'Michael'
        expect(subject.details.email).to eq 'michael@intridea.com'
        expect(subject.details.address).to be_nil
        expect(subject.details.city).to eq 'Imagineton'
      end

      it 'clones before a #regular_merge' do
        duped = subject.shallow_merge(details: { address: 'Fake street' })
        expect(duped).not_to eql(subject)
      end

      it 'default #merge is shallow' do
        duped = subject.shallow_merge(details: { address: 'Fake street' })
        expect(duped.details.address).to eq 'Fake street'
        expect(subject.details.address).to eq 'Nowhere road'
        expect(duped.details.email).to be_nil
      end
    end

    describe '#replace' do
      before do
        subject.replace(
          middle_name: 'Cain',
          details: { city: 'Imagination' }
        )
      end

      it 'returns self' do
        expect(subject.replace(foo: 'bar').to_hash).to eq('foo' => 'bar')
      end

      it 'sets all specified keys to their corresponding values' do
        expect(subject.middle_name?).to be true
        expect(subject.details?).to be true
        expect(subject.middle_name).to eq 'Cain'
        expect(subject.details.city?).to be true
        expect(subject.details.city).to eq 'Imagination'
      end

      it 'leaves only specified keys' do
        expect(subject.keys.sort).to eq %w(details middle_name)
        expect(subject.first_name?).to be false
        expect(subject).not_to respond_to(:first_name)
        expect(subject.last_name?).to be false
        expect(subject).not_to respond_to(:last_name)
      end
    end

    describe 'delete' do
      it 'deletes with String key' do
        subject.delete('details')
        expect(subject.details).to be_nil
        expect(subject).not_to be_respond_to :details
      end

      it 'deletes with Symbol key' do
        subject.delete(:details)
        expect(subject.details).to be_nil
        expect(subject).not_to be_respond_to :details
      end
    end
  end

  it 'converts hash assignments into Hashie::Mashes' do
    subject.details = { email: 'randy@asf.com', address: { state: 'TX' } }
    expect(subject.details.email).to eq 'randy@asf.com'
    expect(subject.details.address.state).to eq 'TX'
  end

  it 'does not convert the type of Hashie::Mashes childs to Hashie::Mash' do
    class MyMash < Hashie::Mash
    end

    record = MyMash.new
    record.son = MyMash.new
    expect(record.son.class).to eq MyMash
  end

  it 'does not change the class of Mashes when converted' do
    class SubMash < Hashie::Mash
    end

    record = Hashie::Mash.new
    son = SubMash.new
    record['submash'] = son
    expect(record['submash']).to be_kind_of(SubMash)
  end

  it 'respects the class when passed a bang method for a non-existent key' do
    record = Hashie::Mash.new
    expect(record.non_existent!).to be_kind_of(Hashie::Mash)

    class SubMash < Hashie::Mash
    end

    son = SubMash.new
    expect(son.non_existent!).to be_kind_of(SubMash)
  end

  it 'respects the class when passed an under bang method for a non-existent key' do
    record = Hashie::Mash.new
    expect(record.non_existent_).to be_kind_of(Hashie::Mash)

    class SubMash < Hashie::Mash
    end

    son = SubMash.new
    expect(son.non_existent_).to be_kind_of(SubMash)
  end

  it 'respects the class when converting the value' do
    record = Hashie::Mash.new
    record.details = Hashie::Mash.new(email: 'randy@asf.com')
    expect(record.details).to be_kind_of(Hashie::Mash)
  end

  it 'respects another subclass when converting the value' do
    record = Hashie::Mash.new

    class SubMash < Hashie::Mash
    end

    son = SubMash.new(email: 'foo@bar.com')
    record.details = son
    expect(record.details).to be_kind_of(SubMash)
  end

  describe '#respond_to?' do
    it 'responds to a normal method' do
      expect(Hashie::Mash.new).to be_respond_to(:key?)
    end

    it 'responds to a set key' do
      expect(Hashie::Mash.new(abc: 'def')).to be_respond_to(:abc)
    end

    it 'responds to a set key with a suffix' do
      %w(= ? ! _).each do |suffix|
        expect(Hashie::Mash.new(abc: 'def')).to be_respond_to(:"abc#{suffix}")
      end
    end

    it 'does not respond to an unknown key with a suffix' do
      %w(= ? ! _).each do |suffix|
        expect(Hashie::Mash.new(abc: 'def')).not_to be_respond_to(:"xyz#{suffix}")
      end
    end

    it 'does not respond to an unknown key without a suffix' do
      expect(Hashie::Mash.new(abc: 'def')).not_to be_respond_to(:xyz)
    end

    it 'does not respond to permitted?' do
      expect(Hashie::Mash.new).not_to be_respond_to(:permitted?)
    end
  end

  context '#initialize' do
    it 'converts an existing hash to a Hashie::Mash' do
      converted = Hashie::Mash.new(abc: 123, name: 'Bob')
      expect(converted.abc).to eq 123
      expect(converted.name).to eq 'Bob'
    end

    it 'converts hashes recursively into Hashie::Mashes' do
      converted = Hashie::Mash.new(a: { b: 1, c: { d: 23 } })
      expect(converted.a.is_a?(Hashie::Mash)).to be true
      expect(converted.a.b).to eq 1
      expect(converted.a.c.d).to eq 23
    end

    it 'converts hashes in arrays into Hashie::Mashes' do
      converted = Hashie::Mash.new(a: [{ b: 12 }, 23])
      expect(converted.a.first.b).to eq 12
      expect(converted.a.last).to eq 23
    end

    it 'converts an existing Hashie::Mash into a Hashie::Mash' do
      initial = Hashie::Mash.new(name: 'randy', address: { state: 'TX' })
      copy = Hashie::Mash.new(initial)
      expect(initial.name).to eq copy.name
      expect(initial.__id__).not_to eq copy.__id__
      expect(copy.address.state).to eq 'TX'
      copy.address.state = 'MI'
      expect(initial.address.state).to eq 'TX'
      expect(copy.address.__id__).not_to eq initial.address.__id__
    end

    it 'accepts a default block' do
      initial = Hashie::Mash.new { |h, i| h[i] = [] }
      expect(initial.default_proc).not_to be_nil
      expect(initial.default).to be_nil
      expect(initial.test).to eq []
      expect(initial.test?).to be true
    end

    it 'converts Hashie::Mashes within Arrays back to Hashes' do
      initial_hash = { 'a' => [{ 'b' => 12, 'c' => ['d' => 50, 'e' => 51] }, 23] }
      converted = Hashie::Mash.new(initial_hash)
      expect(converted.to_hash['a'].first.is_a?(Hashie::Mash)).to be false
      expect(converted.to_hash['a'].first.is_a?(Hash)).to be true
      expect(converted.to_hash['a'].first['c'].first.is_a?(Hashie::Mash)).to be false
    end
  end

  describe '#fetch' do
    let(:hash) { { one: 1, other: false } }
    let(:mash) { Hashie::Mash.new(hash) }

    context 'when key exists' do
      it 'returns the value' do
        expect(mash.fetch(:one)).to eql(1)
      end

      it 'returns the value even if the value is falsy' do
        expect(mash.fetch(:other)).to eql(false)
      end

      context 'when key has other than original but acceptable type' do
        it 'returns the value' do
          expect(mash.fetch('one')).to eql(1)
        end
      end
    end

    context 'when key does not exist' do
      it 'raises KeyError' do
        error = RUBY_VERSION =~ /1.8/ ? IndexError : KeyError
        expect { mash.fetch(:two) }.to raise_error(error)
      end

      context 'with default value given' do
        it 'returns default value' do
          expect(mash.fetch(:two, 8)).to eql(8)
        end

        it 'returns default value even if it is falsy' do
          expect(mash.fetch(:two, false)).to eql(false)
        end
      end

      context 'with block given' do
        it 'returns default value' do
          expect(mash.fetch(:two) do |key|
            'block default value'
          end).to eql('block default value')
        end
      end
    end
  end

  describe '#to_hash' do
    let(:hash) { { 'outer' => { 'inner' => 42 }, 'testing' => [1, 2, 3] } }
    let(:mash) { Hashie::Mash.new(hash) }

    it 'returns a standard Hash' do
      expect(mash.to_hash).to be_a(::Hash)
    end

    it 'includes all keys' do
      expect(mash.to_hash.keys).to eql(%w(outer testing))
    end

    it 'converts keys to symbols when symbolize_keys option is true' do
      expect(mash.to_hash(symbolize_keys: true).keys).to include(:outer)
      expect(mash.to_hash(symbolize_keys: true).keys).not_to include('outer')
    end

    it 'leaves keys as strings when symbolize_keys option is false' do
      expect(mash.to_hash(symbolize_keys: false).keys).to include('outer')
      expect(mash.to_hash(symbolize_keys: false).keys).not_to include(:outer)
    end

    it 'symbolizes keys recursively' do
      expect(mash.to_hash(symbolize_keys: true)[:outer].keys).to include(:inner)
      expect(mash.to_hash(symbolize_keys: true)[:outer].keys).not_to include('inner')
    end
  end
end
