# frozen_string_literal: true

require 'spec_helper'

describe Hashie::Mash do
  subject { described_class.new }

  include_context 'with a logger'

  it 'inherits from Hash' do
    expect(subject).to be_a(Hash)
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
    expect(subject).not_to be_test
    subject.test = 'abc'
    expect(subject).to be_test
  end

  it 'returns false on a ? method if a value has been set to nil or false' do
    subject.test = nil
    expect(subject).not_to be_test
    subject.test = false
    expect(subject).not_to be_test
  end

  it 'makes all [] and []= into strings for consistency' do
    subject['abc'] = 123
    expect(subject).to be_key('abc')
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
    expect(subject.abc('foobar')).to be_nil
    subject.abc = 123
    expect(subject.abc('foobar')).to eq 123
  end

  # Added due to downstream gems assuming indifferent access to be true for Mash
  # When this is not, bump major version so that downstream gems can target
  # correct version and fix accordingly.
  # See https://github.com/hashie/hashie/pull/197
  it 'maintains indifferent access when nested' do
    subject[:a] = { b: 'c' }
    expect(subject[:a][:b]).to eq 'c'
    expect(subject[:a]['b']).to eq 'c'
  end

  it 'returns a Hashie::Mash when passed a bang method to a nonexistent key' do
    expect(subject.abc!).to be_a(described_class)
  end

  it 'returns the existing value when passed a bang method for an existing key' do
    subject.name = 'Bob'
    expect(subject.name!).to eq 'Bob'
  end

  it 'returns a Hashie::Mash when passed an under bang method to a nonexistent key' do
    expect(subject.abc_).to be_a(described_class)
  end

  it 'returns the existing value when passed an under bang method for an existing key' do
    subject.name = 'Bob'
    expect(subject.name_).to eq 'Bob'
  end

  it '#initializing_reader returns a Hashie::Mash when passed a non-existent key' do
    expect(subject.initializing_reader(:abc)).to be_a(described_class)
  end

  it 'allows for multi-level assignment through bang methods' do
    subject.author!.name = 'Michael Bleigh'
    expect(subject.author).to eq described_class.new(name: 'Michael Bleigh')
    subject.author!.website!.url = 'http://www.mbleigh.com/'
    expect(subject.author.website).to eq described_class.new(url: 'http://www.mbleigh.com/')
  end

  it 'allows for multi-level under bang testing' do
    expect(subject.author_.website_.url).to be_nil
    expect(subject.author_.website_.url?).to be false
    expect(subject.author).to be_nil
  end

  it 'does not call super if id is not a key' do
    expect(subject.id).to be_nil
  end

  it 'returns the value if id is a key' do
    subject.id = 'Steve'
    expect(subject.id).to eq 'Steve'
  end

  it 'does not call super if type is not a key' do
    expect(subject.type).to be_nil
  end

  it 'returns the value if type is a key' do
    subject.type = 'Steve'
    expect(subject.type).to eq 'Steve'
  end

  include_context 'with a logger' do
    it 'logs a warning when overriding built-in methods' do
      described_class.new('object_id' => { 'two' => 2 })

      expect(logger_output).to match('Hashie::Mash#object_id')
    end

    it 'can set keys more than once and does not warn when doing so' do
      mash = described_class.new
      mash[:test_key] = 'Test value'

      expect { mash[:test_key] = 'A new value' }.not_to raise_error
      expect(logger_output).to be_empty
    end

    it 'does not write to the logger when warnings are disabled' do
      mash_class = Class.new(Hashie::Mash) do
        disable_warnings
      end
      mash_class.new('trust' => { 'two' => 2 })

      expect(logger_output).to be_empty
    end

    it 'does not write to the logger when setting most affixed keys' do
      underbang = described_class.new('foo_' => 'foo')
      bang = described_class.new('foo!' => 'foo')
      query = described_class.new('foo?' => 'foo')

      expect(logger_output).to be_empty
      expect(underbang.foo_).to eq 'foo'
      expect(bang.foo!).to eq 'foo'
      expect(query.foo?).to eq 'foo'
    end

    it 'warns when setting a key that looks like a setter' do
      setter = described_class.new('foo=' => 'foo')

      expect(logger_output).to match 'Hashie::Mash#foo='
      expect('setter.foo=').not_to parse_as_valid_ruby

      setter.foo = 'bar'

      expect(setter.to_h).to eq 'foo=' => 'foo'
    end

    it 'cannot disable logging on the base Mash' do
      expected_error = Hashie::Extensions::KeyConflictWarning::CannotDisableMashWarnings

      expect { described_class.disable_warnings }.to raise_error(expected_error)
    end

    it 'carries over the disable for warnings on grandchild classes' do
      child_class = Class.new(Hashie::Mash) do
        disable_warnings
      end
      grandchild_class = Class.new(child_class)

      grandchild_class.new('trust' => { 'two' => 2 })

      expect(logger_output).to be_empty
    end

    it 'writes to logger when a key is overridden that is not ignored' do
      mash_class = Class.new(Hashie::Mash) do
        disable_warnings :merge
      end

      mash_class.new('address' => { 'zip' => '90210' })
      expect(logger_output).not_to be_empty
    end

    it 'does not write to logger when a key is overridden that is ignored' do
      mash_class = Class.new(Hashie::Mash) do
        disable_warnings :zip
      end

      mash_class.new('address' => { 'zip' => '90210' })
      expect(logger_output).to be_empty
    end

    it 'carries over the ignored warnings list for warnings on grandchild classes' do
      child_class = Class.new(Hashie::Mash) do
        disable_warnings :zip, :merge
      end
      grandchild_class = Class.new(child_class)

      grandchild_class.new('address' => { 'zip' => '90210' }, 'merge' => true)

      expect(grandchild_class.disabled_warnings).to eq(%i[zip merge])
      expect(logger_output).to be_empty
    end

    context 'multiple disable_warnings calls' do
      context 'calling disable_warnings multiple times with parameters' do
        it 'appends each new parameter to the ignore list' do
          child_class = Class.new(Hashie::Mash) do
            disable_warnings :zip
            disable_warnings :merge
            disable_warnings :cycle
          end

          expect(child_class.disabled_warnings).to eq(%i[zip merge cycle])
        end
      end

      context 'calling disable_warnings without keys after calling with keys' do
        it 'uses the last call to determine the ignore list' do
          child_class = Class.new(Hashie::Mash) do
            disable_warnings :zip
            disable_warnings
          end

          child_class.new('address' => { 'zip' => '90210' }, 'merge' => true, 'cycle' => 'bi')

          expect(child_class.disabled_warnings).to eq([])
          expect(logger_output).to be_empty
        end
      end

      context 'calling disable_parameters with keys after calling without keys' do
        it 'only ignores logging for ignored methods' do
          child_class = Class.new(Hashie::Mash) do
            disable_warnings
            disable_warnings :zip
          end

          child_class.new('address' => { 'zip' => '90210' }, 'merge' => true)

          expect(logger_output).to match(/#{child_class}#merge/)
          expect(logger_output).not_to match(/#{child_class}#zip/)
        end
      end
    end
  end

  context 'updating' do
    subject do
      described_class.new(
        first_name: 'Michael',
        last_name: 'Bleigh',
        details: {
          email: 'michael@asf.com',
          address: 'Nowhere road'
        }
      )
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
        expect(subject).to receive(:convert_value).once
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
        duped = subject.merge(details: { address: 'Pasadena CA' }) do |_, oldv, newv|
          [oldv, newv].join(', ')
        end

        expect(duped.details.address).to eq 'Nowhere road, Pasadena CA'
      end

      it 'copies values for non-duplicate keys when a block is supplied' do
        m_hash = { details: { address: 'Pasadena CA', state: 'West Thoughtleby' } }
        duped = subject.merge(m_hash) { |_, oldv, _| oldv }

        expect(duped.details.address).to eq 'Nowhere road'
        expect(duped.details.state).to eq 'West Thoughtleby'
      end

      it 'does not raise an exception when default_proc raises an error' do
        hash = described_class.new(a: 1) { |_k, _v| raise('Should not be raise I') }
        other_has = described_class.new(a: 2, b: 2) { |_k, _v| raise('Should not be raise II') }
        expected_hash = described_class.new(a: 2, b: 2)

        res = hash.merge(other_has)
        expect(res).to eq(expected_hash)
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
        expect(subject).to be_middle_name
        expect(subject).to be_details
        expect(subject.middle_name).to eq 'Cain'
        expect(subject.details).to be_city
        expect(subject.details.city).to eq 'Imagination'
      end

      it 'leaves only specified keys' do
        expect(subject.keys.sort).to eq %w[details middle_name]
        expect(subject).not_to be_first_name
        expect(subject).not_to respond_to(:first_name)
        expect(subject).not_to be_last_name
        expect(subject).not_to respond_to(:last_name)
      end
    end

    describe 'delete' do
      it 'deletes with String key' do
        subject.delete('details')
        expect(subject.details).to be_nil
        expect(subject).not_to respond_to :details
      end

      it 'deletes with Symbol key' do
        subject.delete(:details)
        expect(subject.details).to be_nil
        expect(subject).not_to respond_to :details
      end
    end
  end

  it 'converts hash assignments into Hashie::Mashes' do
    subject.details = { email: 'randy@asf.com', address: { state: 'TX' } }
    expect(subject.details.email).to eq 'randy@asf.com'
    expect(subject.details.address.state).to eq 'TX'
  end

  it 'does not convert the type of nested Mash subclasses to Hashie::Mash' do
    class MyMash < Hashie::Mash
    end

    record = MyMash.new
    record.son = MyMash.new
    expect(record.son.class).to eq MyMash
  end

  it 'does not change the class of Mashes when converted' do
    class SubMash < Hashie::Mash
    end

    record = described_class.new
    son = SubMash.new
    record['submash'] = son
    expect(record['submash']).to be_a(SubMash)
  end

  it 'respects the class when passed a bang method for a non-existent key' do
    record = described_class.new
    expect(record.non_existent!).to be_a(described_class)

    class SubMash < Hashie::Mash
    end

    son = SubMash.new
    expect(son.non_existent!).to be_a(SubMash)
  end

  it 'respects the class when passed an under bang method for a non-existent key' do
    record = described_class.new
    expect(record.non_existent_).to be_a(described_class)

    class SubMash < Hashie::Mash
    end

    son = SubMash.new
    expect(son.non_existent_).to be_a(SubMash)
  end

  it 'respects the class when converting the value' do
    record = described_class.new
    record.details = described_class.new(email: 'randy@asf.com')
    expect(record.details).to be_a(described_class)
  end

  it 'respects another subclass when converting the value' do
    record = described_class.new

    class SubMash < Hashie::Mash
    end

    son = SubMash.new(email: 'foo@bar.com')
    record.details = son
    expect(record.details).to be_a(SubMash)
  end

  describe 'custom Hash values' do
    let(:hash_class) do
      Class.new(Hash) do
        def label
          :custom
        end
      end
    end
    let(:value) { hash_class[nested: { count: 1 }] }

    it 'retains identity, subclass methods, defaults and unconverted contents on assignment' do
      value.default = :missing
      mash = described_class.new
      mash[:first_value] = value
      mash.second = value
      expect(mash.first_value).to equal(value)
      expect(mash.second).to equal(value)
      expect(mash.first_value.label).to eq(:custom)
      expect(mash.first_value[:absent]).to eq(:missing)
      expect(mash.first_value[:nested]).to be_an_instance_of(Hash)
      value[:nested][:count] = 2
      expect(mash.first_value[:nested][:count]).to eq(2)
    end

    it 'retains custom hashes nested in ordinary hashes and arrays' do
      mash = described_class.new(container: { records: [value, { custom: value }] })
      expect(mash.container).to be_a(described_class)
      expect(mash.container.records).to be_an_instance_of(Hashie::Array)
      expect(mash.container.records.first).to equal(value)
      expect(mash.container.records.last.custom).to equal(value)
    end

    it 'retains identity across initialization, replacement, shallow merging and copying' do
      mash = described_class.new(custom: value)
      expect(mash.custom).to equal(value)
      expect(mash.dup.custom).to equal(value)
      expect(mash.shallow_merge(custom: value).custom).to equal(value)
      expect(mash.replace(custom: value).custom).to equal(value)
      expect(mash.merge(custom: value).custom).to equal(value)
    end

    it 'replaces an existing nested Mash rather than merging a custom Hash into it' do
      mash = described_class.new(custom: { stale: true })
      merged = mash.merge(custom: value)
      expect(merged.custom).to equal(value)
      expect(merged.custom).not_to have_key(:stale)
      expect(mash.custom.stale).to be(true)
      mash.update(custom: value)
      expect(mash.custom).to equal(value)
    end

    it 'passes custom hashes unchanged through merge conflict blocks' do
      mash = described_class.new(custom: { old: true })
      yielded = nil
      mash.update(custom: value) do |_key, _old, incoming|
        yielded = incoming
        incoming
      end
      expect(yielded).to equal(value)
      expect(mash.custom).to equal(value)
    end

    it 'retains custom hashes returned by a merge conflict block' do
      mash = described_class.new(custom: 1)
      mash.update(custom: 2) { |_key, _old, _incoming| value }
      expect(mash.custom).to equal(value)
    end

    it 'allows explicit conversion of a custom root hash while preserving nested custom values' do
      value[:custom] = hash_class[name: 'Ada']
      converted = described_class.new(value)
      expect(converted).to be_an_instance_of(described_class)
      expect(converted.nested).to be_an_instance_of(described_class)
      expect(converted.nested[:count]).to eq(1)
      expect(converted.custom).to equal(value[:custom])
    end

    it 'does not duplicate frozen custom hashes during initialization or copying' do
      value.freeze
      mash = described_class.new(custom: value)
      expect(mash.dup.custom).to equal(value)
      expect(mash.custom).to be_frozen
    end

    it 'retains Hashie Hash subclasses other than Mash without rebuilding or copying them' do
      dash_class = Class.new(Hashie::Dash) { property :name, required: true }
      dash = dash_class.new(name: 'Ada')
      mash = described_class.new(record: dash)
      expect(mash.record).to equal(dash)
      expect(mash.dup.record).to equal(dash)
    end

    it 'continues to convert plain hashes into the receiving Mash subclass' do
      klass = Class.new(described_class)
      mash = klass.new(custom: value, plain: { count: 1 })
      expect(mash.custom).to equal(value)
      expect(mash.plain).to be_an_instance_of(klass)
      mash.update(plain: { extra: 2 })
      expect(mash.plain[:count]).to eq(1)
      expect(mash.plain.extra).to eq(2)
    end
  end

  describe '#respond_to?' do
    subject do
      described_class.new(abc: 'def')
    end

    it 'responds to a normal method' do
      expect(subject).to respond_to(:key?)
    end

    it 'responds to a set key' do
      expect(subject).to respond_to(:abc)
      expect(subject.method(:abc)).not_to be_nil
    end

    it 'responds to a set key with a suffix' do
      %w[= ? ! _].each do |suffix|
        expect(subject).to respond_to(:"abc#{suffix}")
      end
    end

    it 'is able to access the suffixed key as a method' do
      %w[= ? ! _].each do |suffix|
        expect(subject.method(:"abc#{suffix}")).not_to be_nil
      end
    end

    it 'responds to an unknown key with a suffix' do
      %w[= ? ! _].each do |suffix|
        expect(subject).to respond_to(:"xyz#{suffix}")
      end
    end

    it 'is able to access an unknown suffixed key as a method' do
      # See https://github.com/intridea/hashie/pull/285 for more information
      pending_for(engine: 'ruby', versions: %w[2.2.0 2.2.1 2.2.2])

      %w[= ? ! _].each do |suffix|
        expect(subject.method(:"xyz#{suffix}")).not_to be_nil
      end
    end

    it 'does not respond to an unknown key without a suffix' do
      expect(subject).not_to respond_to(:xyz)
      expect { subject.method(:xyz) }.to raise_error(NameError)
    end
  end

  describe 'accessing a key that is itself suffixed' do
    it 'reads a key literally ending in ? via the method accessor' do
      mash = described_class.new('foo?' => 'literal')
      expect(mash.foo?).to eq('literal')
    end

    it 'ignores a write and returns the literal value when the key ends in =' do
      mash = described_class.new('foo=' => 'literal')
      mash.foo = 'ignored'
      expect(mash['foo=']).to eq('literal')
    end

    it 'reads a key literally ending in ! via the method accessor' do
      mash = described_class.new('foo!' => 'literal')
      expect(mash.foo!).to eq('literal')
    end

    it 'reads a key literally ending in _ via the method accessor' do
      mash = described_class.new('foo_' => 'literal')
      expect(mash.foo_).to eq('literal')
    end
  end

  describe '#prefix_method?' do
    subject do
      described_class.new(abc: 'def')
    end

    it 'is true for a set key with an allowed suffix' do
      expect(subject.send(:prefix_method?, 'abc?')).to be true
    end

    it 'is false for an unset key with an allowed suffix' do
      expect(subject.send(:prefix_method?, 'xyz?')).to be false
    end
  end

  describe '#extractable_options?' do
    it 'is true, playing nice with ActiveSupport Array#extract_options!' do
      expect(described_class.new.extractable_options?).to be true
    end
  end

  describe '#initialize' do
    it 'converts an existing hash to a Hashie::Mash' do
      converted = described_class.new(abc: 123, name: 'Bob')
      expect(converted.abc).to eq 123
      expect(converted.name).to eq 'Bob'
    end

    it 'converts hashes recursively into Hashie::Mashes' do
      converted = described_class.new(a: { b: 1, c: { d: 23 } })
      expect(converted.a).to be_a(described_class)
      expect(converted.a.b).to eq 1
      expect(converted.a.c.d).to eq 23
    end

    it 'converts hashes in arrays into Hashie::Mashes' do
      converted = described_class.new(a: [{ b: 12 }, 23])
      expect(converted.a.first.b).to eq 12
      expect(converted.a.last).to eq 23
    end

    it 'copies frozen nested arrays while retaining Hashie array behavior' do
      hash = { b: 12 }.freeze
      nested = [hash, 23].freeze
      source = [nested, [].freeze].freeze
      converted = described_class.new(a: source).a

      expect(converted).to be_an_instance_of(Hashie::Array)
      expect(converted.first).to be_an_instance_of(Hashie::Array)
      expect(converted.last).to be_an_instance_of(Hashie::Array)
      expect(converted.dig('0', '0').b).to eq(12)
      converted.first.first.b = 42
      converted.first << 24
      expect(source).to eq([[{ b: 12 }, 23], []])
    end

    it 'converts array subclasses to independent Hashie arrays on assignment' do
      source = Class.new(Array).new([{ b: 12 }.freeze]).freeze
      converted = described_class.new
      converted.a = source

      expect(converted.a).to be_an_instance_of(Hashie::Array)
      expect(converted.a.first).to be_a(described_class)
      converted.a << 23
      expect(source.length).to eq(1)
    end

    it 'converts an existing Hashie::Mash into a Hashie::Mash' do
      initial = described_class.new(name: 'randy', address: { state: 'TX' })
      copy = described_class.new(initial)
      expect(initial.name).to eq copy.name
      expect(initial.__id__).not_to eq copy.__id__
      expect(copy.address.state).to eq 'TX'
      copy.address.state = 'MI'
      expect(initial.address.state).to eq 'TX'
      expect(copy.address.__id__).not_to eq initial.address.__id__
    end

    it 'accepts a default block' do
      initial = described_class.new { |h, i| h[i] = [] }
      expect(initial.default_proc).not_to be_nil
      expect(initial.default).to be_nil
      expect(initial.test).to eq []
      expect(initial).to be_test
    end

    it 'allows propagation of a default block' do
      h = described_class.new { |mash, key| mash[key] = mash.class.new(&mash.default_proc) }
      expect { h[:x][:y][:z] = :xyz }.not_to raise_error
      expect(h.x.y.z).to eq(:xyz)
      expect(h[:x][:y][:z]).to eq(:xyz)
    end

    it 'allows assignment of an empty array in a default block' do
      initial = described_class.new { |h, k| h[k] = [] }
      initial.hello << 100
      expect(initial.hello).to eq [100]
      initial['hi'] << 100
      expect(initial['hi']).to eq [100]
    end

    it 'allows assignment of a non-empty array in a default block' do
      initial = described_class.new { |h, k| h[k] = [100] }
      initial.hello << 200
      expect(initial.hello).to eq [100, 200]
      initial['hi'] << 200
      expect(initial['hi']).to eq [100, 200]
    end

    it 'allows assignment of an empty hash in a default block' do
      initial = described_class.new { |h, k| h[k] = {} }
      initial.hello[:a] = 100
      expect(initial.hello).to eq described_class.new(a: 100)
      initial[:hi][:a] = 100
      expect(initial[:hi]).to eq described_class.new(a: 100)
    end

    it 'allows assignment of a non-empty hash in a default block' do
      initial = described_class.new { |h, k| h[k] = { a: 100 } }
      initial.hello[:b] = 200
      expect(initial.hello).to eq described_class.new(a: 100, b: 200)
      initial[:hi][:b] = 200
      expect(initial[:hi]).to eq described_class.new(a: 100, b: 200)
    end

    it 'converts Hashie::Mashes within Arrays back to Hashes' do
      initial_hash = { 'a' => [{ 'b' => 12, 'c' => [{ 'd' => 50, 'e' => 51 }] }, 23] }
      converted = described_class.new(initial_hash)
      expect(converted.to_hash['a'].first).not_to be_a(described_class)
      expect(converted.to_hash['a'].first).to be_a(Hash)
      expect(converted.to_hash['a'].first['c'].first).not_to be_a(described_class)
    end

    it 'only stringifies keys which can be converted to symbols' do
      initial_hash = { 1 => 'a', ['b'] => 2, 'c' => 3, d: 4 }
      converted = described_class.new(initial_hash)
      expect(converted).to eq(1 => 'a', ['b'] => 2, 'c' => 3, 'd' => 4)
    end

    it 'preserves keys which cannot be converted to symbols' do
      initial_hash = { 1 => 'a', '1' => 'b', :'1' => 'c' }
      converted = described_class.new(initial_hash)
      expect(converted).to eq(1 => 'a', '1' => 'c')
    end
  end

  describe '#dup' do
    # bind_call itself allocates on MRI before 3.2.
    it 'allocates no more than building the copy with new', if: RUBY_ENGINE == 'ruby' && RUBY_VERSION >= '3.2' do
      mash = described_class.new('abc' => 1)
      mash_class = described_class
      allocations = lambda do |&block|
        before = GC.stat(:total_allocated_objects)
        block.call
        GC.stat(:total_allocated_objects) - before
      end
      copy = -> { mash.dup }
      build = -> { mash_class.new(mash, nil) }
      5.times do
        allocations.call(&copy)
        allocations.call(&build)
      end
      copy_with_new = allocations.call(&build)
      expect(allocations.call(&copy)).to be <= copy_with_new
    end
  end

  describe 'symbol keys' do
    it 'address the same entries as their string names' do
      mash = described_class.new
      mash[:abc] = 1
      expect(mash.keys).to eq(['abc'])
      expect(mash['abc']).to eq(1)
      expect(mash.key?(:abc)).to be(true)
      expect(mash.fetch(:abc)).to eq(1)
      expect(mash.values_at(:abc)).to eq([1])
      expect(mash.delete(:abc)).to eq(1)
      expect(mash).to be_empty
    end

    it 'are read without allocating a string', if: RUBY_ENGINE == 'ruby' do
      mash = described_class.new('abc' => 1)
      allocations = lambda do |&block|
        before = GC.stat(:total_allocated_objects)
        block.call
        GC.stat(:total_allocated_objects) - before
      end
      allocations.call { mash[:abc] } # warm up
      expect(allocations.call { 100.times { mash[:abc] } }).to eq(0)
    end
  end

  describe '#fetch' do
    let(:hash) { { one: 1, other: false } }
    let(:mash) { described_class.new(hash) }

    context 'when key exists' do
      it 'returns the value' do
        expect(mash.fetch(:one)).to be(1)
      end

      it 'returns the value even if the value is falsy' do
        expect(mash.fetch(:other)).to be(false)
      end

      context 'when key has other than original but acceptable type' do
        it 'returns the value' do
          expect(mash.fetch('one')).to be(1)
        end
      end
    end

    context 'when key does not exist' do
      it 'raises KeyError' do
        expect { mash.fetch(:two) }.to raise_error(KeyError)
      end

      context 'with default value given' do
        it 'returns default value' do
          expect(mash.fetch(:two, 8)).to be(8)
        end

        it 'returns default value even if it is falsy' do
          expect(mash.fetch(:two, false)).to be(false)
        end
      end

      context 'with block given' do
        it 'returns default value' do
          expect(mash.fetch(:two, 'block default value')).to eql('block default value')
        end
      end
    end
  end

  describe '#to_hash' do
    let(:hash) { { 'outer' => { 'inner' => 42 }, 'testing' => [1, 2, 3] } }
    let(:mash) { described_class.new(hash) }

    it 'returns a standard Hash' do
      expect(mash.to_hash).to be_a(Hash)
    end

    it 'includes all keys' do
      expect(mash.to_hash.keys).to eql(%w[outer testing])
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

  describe '#stringify_keys' do
    it 'turns all keys into strings recursively' do
      hash = described_class[:a => 'hey', 123 => { 345 => 'hey' }]
      hash.stringify_keys!
      expect(hash).to eq Hashie::Hash['a' => 'hey', '123' => { '345' => 'hey' }]
    end
  end

  describe '#values_at' do
    let(:hash) { { 'key_one' => 1, :key_two => 2 } }
    let(:mash) { described_class.new(hash) }

    context 'when the original type is given' do
      it 'returns the values' do
        expect(mash.values_at('key_one', :key_two)).to eq([1, 2])
      end
    end

    context 'when a different, but acceptable type is given' do
      it 'returns the values' do
        expect(mash.values_at(:key_one, 'key_two')).to eq([1, 2])
      end
    end

    context 'when a key is given that is not in the Mash' do
      it 'returns nil for that value' do
        expect(mash.values_at('key_one', :key_three)).to eq([1, nil])
      end
    end
  end

  describe '.load(filename, options = {})' do
    subject { described_class.load(path, parser: parser) }

    let(:config) do
      {
        'production' => {
          'foo' => 'production_foo'
        }
      }
    end
    let(:path) { 'database.yml' }
    let(:parser) { double(:parser) }

    before do |ex|
      unless ex.metadata == :test_cache
        described_class.instance_variable_set('@_mashes', nil) # clean the cached mashes
      end
    end

    context 'if the file exists' do
      before do
        expect(File).to receive(:file?).with(path).and_return(true)
        expect(parser).to receive(:perform).with(path, {}).and_return(config)
      end

      it { is_expected.to be_a(described_class) }

      it 'return a Mash from a file' do
        expect(subject.production).not_to be_nil
        expect(subject.production.keys).to eq config['production'].keys
        expect(subject.production.foo).to eq config['production']['foo']
      end

      it 'freeze the attributes' do
        expect { subject.production = {} }.to raise_exception(RuntimeError, /can't modify frozen/)
      end
    end

    context 'if the files does not exists' do
      before do
        expect(File).to receive(:file?).with(path).and_return(false)
      end

      it 'raise an ArgumentError' do
        expect { subject }.to raise_exception(ArgumentError, "file not found: `#{path}`")
      end
    end

    context 'if the file is passed as Pathname' do
      require 'pathname'
      let(:path) { Pathname.new('database.yml') }

      before do
        expect(File).to receive(:file?).with(path).and_return(true)
        expect(parser).to receive(:perform).with(path, {}).and_return(config)
      end

      it 'return a Mash from a file' do
        expect(subject.production.foo).to eq config['production']['foo']
      end
    end

    describe 'results are cached' do
      subject { described_class.load(path, parser: parser) }

      let(:parser) { double(:parser) }

      before do
        expect(File).to receive(:file?).with(path).and_return(true)
        expect(File).to receive(:file?).with("#{path}+1").and_return(true)
        expect(parser).to receive(:perform).once.with(path, {}).and_return(config)
        expect(parser).to receive(:perform).once.with("#{path}+1", {}).and_return(config)
      end

      it 'cache the loaded yml file', :test_cache do
        2.times do
          expect(subject).to be_a(described_class)
          expect(described_class.load("#{path}+1", parser: parser)).to be_a(described_class)
        end

        cached = described_class.load(path, parser: parser)
        expect(described_class.load(path, parser: parser)).to equal(cached)
      end
    end

    context 'when the file has aliases in it' do
      it 'can use the aliases and does not raise an error' do
        mash = described_class.load('spec/fixtures/yaml_with_aliases.yml')
        expect(mash.company_a.accounts.admin.password).to eq('secret')
      end

      it 'can override the value of aliases' do
        # Psych >= 5 raises Psych::AliasesNotEnabled ("Alias parsing was not
        # enabled"), a subclass of Psych::BadAlias, which older Psych
        # versions raise directly (mentioning the unresolved alias name).
        expect do
          described_class.load('spec/fixtures/yaml_with_aliases.yml', aliases: false)
        end.to raise_error(Psych::BadAlias, /Alias parsing was not enabled|base_accounts/)
      end
    end

    it 'leaves ERB as literal text with the default parser' do
      mash = described_class.load('spec/fixtures/yaml_with_erb.yml')
      expect(mash.value).to eq("<%= 'evaluated' %>")
    end

    it 'evaluates ERB only when the ERB parser is selected explicitly' do
      mash = described_class.load(
        'spec/fixtures/yaml_with_erb.yml',
        parser: Hashie::Extensions::Parsers::YamlErbParser
      )
      expect(mash.value).to eq('evaluated')
    end

    it 'does not execute embedded Ruby by default' do
      expect(File).to receive(:file?).with(path).and_return(true)
      expect(File).to receive(:read).with(path).and_return("value: \"<% raise 'must not run' %>\"\n")

      expect(described_class.load(path).value).to eq("<% raise 'must not run' %>")
    end

    context 'when the file has symbols' do
      it 'can override the value of permitted_classes' do
        mash = described_class.load('spec/fixtures/yaml_with_symbols.yml', permitted_classes: [Symbol])
        expect(mash.user_icon.width).to eq(200)
      end

      it 'uses defaults for permitted_classes' do
        expect do
          described_class.load('spec/fixtures/yaml_with_symbols.yml')
        end.to raise_error Psych::DisallowedClass, /Symbol/
      end

      it 'can override the value of permitted_symbols' do
        mash = described_class.load('spec/fixtures/yaml_with_symbols.yml',
                                    permitted_classes: [Symbol],
                                    permitted_symbols: %i[
                                      user_icon
                                      width
                                      height
                                    ])
        expect(mash.user_icon.width).to eq(200)
      end

      it 'raises an error on insufficient permitted_symbols' do
        expect do
          described_class.load('spec/fixtures/yaml_with_symbols.yml',
                               permitted_classes: [Symbol],
                               permitted_symbols: %i[
                                 user_icon
                                 width
                               ])
        end.to raise_error Psych::DisallowedClass, /Symbol/
      end
    end
  end

  describe '#to_module(mash_method_name)' do
    subject { Class.new.extend mash.to_module }

    let(:mash) { described_class.new }

    it 'defines a settings method on the klass class that extends the module' do
      expect(subject).to respond_to(:settings)
      expect(subject.settings).to eq mash
    end

    context 'when a settings_method_name is set' do
      subject { Class.new.extend mash.to_module(mash_method_name) }

      let(:mash_method_name) { 'config' }

      it 'defines a settings method on the klass class that extends the module' do
        expect(subject).to respond_to(mash_method_name.to_sym)
        expect(subject.send(mash_method_name.to_sym)).to eq mash
      end
    end
  end

  describe '#reverse_merge' do
    subject { described_class.new(a: 1, b: 2) }

    it 'unifies strings and symbols' do
      expect(subject.reverse_merge(a: 2).length).to eq 2
      expect(subject.reverse_merge('a' => 2).length).to eq 2
    end

    it 'does not overwrite values' do
      expect(subject.reverse_merge(a: 5).a).to eq subject.a
    end

    context 'when using with subclass' do
      subject { subclass.new(a: 1) }

      let(:subclass) { Class.new(described_class) }

      it 'creates an instance of subclass' do
        expect(subject.reverse_merge(a: 5)).to be_a(subclass)
      end
    end
  end

  describe '#invert' do
    subject(:mash) { described_class.new(a: 'apple', b: 4) }

    it 'returns a Hashie::Mash' do
      expect(mash.invert).to be_a(described_class)
    end

    it 'returns a mash with the keys and values inverted' do
      expect(mash.invert).to eq('apple' => 'a', 4 => 'b')
    end

    context 'when using with subclass' do
      subject(:sub_mash) { subclass.new(a: 1, b: nil) }

      let(:subclass) { Class.new(described_class) }

      it 'creates an instance of subclass' do
        expect(sub_mash.invert).to be_a(subclass)
      end
    end
  end

  describe '#reject' do
    subject(:mash) { described_class.new(a: 'apple', b: 4) }

    it 'returns a Hashie::Mash' do
      expect(mash.reject { |_key, value| value.is_a?(Integer) }).to be_a(described_class)
    end

    it 'rejects keys for which the block returns true' do
      expect(mash.reject { |_key, value| value.is_a?(Integer) }).to eq('a' => 'apple')
      expect(mash).to eq('a' => 'apple', 'b' => 4)
    end

    context 'when using with subclass' do
      subject(:sub_mash) { subclass.new(a: 'apple', b: 4) }

      let(:subclass) { Class.new(described_class) }

      it 'creates an instance of subclass' do
        expect(sub_mash.reject { |_key, value| value.is_a?(Integer) }).to be_a(subclass)
      end
    end
  end

  describe '#select' do
    subject(:mash) { described_class.new(a: 'apple', b: 4) }

    it 'returns a Hashie::Mash' do
      expect(mash.select { |_k, v| v.is_a? String }).to be_a(described_class)
    end

    it 'selects keys for which the block returns true' do
      expect(mash.select { |_k, v| v.is_a? String }).to eq('a' => 'apple')
    end

    context 'when using with subclass' do
      subject(:sub_mash) { subclass.new(a: 1, b: nil) }

      let(:subclass) { Class.new(described_class) }

      it 'creates an instance of subclass' do
        expect(sub_mash.select { |_k, v| v.is_a? String }).to be_a(subclass)
      end
    end
  end

  describe '.quiet' do
    it 'returns a subclass of the calling class' do
      expect(described_class.quiet.new).to be_a(described_class)
    end

    it 'memoizes and returns classes' do
      call_one = described_class.quiet
      call_two = described_class.quiet
      expect(described_class.instance_variable_get('@memoized_classes').count).to eq(1)
      expect(call_one).to eq(call_two)
    end
  end

  describe '#dig' do
    subject { described_class.new(a: { b: 1 }) }

    it 'accepts both string and symbol as key' do
      expect(subject.dig(:a, :b)).to eq(1)
      expect(subject.dig('a', 'b')).to eq(1)
    end

    context 'when the Mash wraps a Hashie::Array' do
      it 'handles digging into an array' do
        mash = described_class.new(alphabet: { first_three: Hashie::Array['a', 'b', 'c'] })

        expect(mash.dig(:alphabet, :first_three, 0)).to eq 'a'
      end
    end
  end

  describe '#transform_values' do
    subject(:mash) { described_class.new(a: 1) }

    it 'returns a Hashie::Mash' do
      expect(mash.transform_values(&:to_s)).to be_a(described_class)
    end

    it 'transforms the value' do
      expect(mash.transform_values(&:to_s).a).to eql('1')
    end

    context 'when using with subclass' do
      subject(:sub_mash) { subclass.new(a: 1).transform_values { |a| a + 2 } }

      let(:subclass) { Class.new(described_class) }

      it 'creates an instance of subclass' do
        expect(sub_mash).to be_a(subclass)
      end
    end

    describe '#compact' do
      subject(:mash) { described_class.new(a: 1, b: nil) }

      it 'returns a Hashie::Mash' do
        expect(mash.compact).to be_a(described_class)
      end

      it 'removes keys with nil values' do
        expect(mash.compact).to eq('a' => 1)
      end

      context 'when using with subclass' do
        subject(:sub_mash) { subclass.new(a: 1, b: nil) }

        let(:subclass) { Class.new(described_class) }

        it 'creates an instance of subclass' do
          expect(sub_mash.compact).to be_a(subclass)
        end
      end
    end
  end

  describe '#slice' do
    subject(:mash) { described_class.new(a: 1, b: 2) }

    it 'returns a Hashie::Mash' do
      expect(mash.slice(:a)).to be_a(described_class)
    end

    it 'returns a Mash with only the keys passed' do
      expect(mash.slice(:a).to_hash).to eq('a' => 1)
    end

    context 'when using with subclass' do
      subject(:sub_mash) { subclass.new(a: 1, b: 2) }

      let(:subclass) { Class.new(described_class) }

      it 'creates an instance of subclass' do
        expect(sub_mash.slice(:a)).to be_a(subclass)
      end
    end
  end

  describe '#transform_keys' do
    subject(:mash) { described_class.new(a: 1, b: 2) }

    it 'returns a Hashie::Mash' do
      expect(mash.transform_keys { |k| k + k }).to be_a(described_class)
    end

    it 'returns a Mash with transformed keys' do
      expect(mash.transform_keys { |k| k + k }).to eq('aa' => 1, 'bb' => 2)
    end

    context 'when using with subclass' do
      subject(:sub_mash) { subclass.new(a: 1, b: 2) }

      let(:subclass) { Class.new(described_class) }

      it 'creates an instance of subclass' do
        expect(sub_mash.transform_keys { |k| k + k }).to be_a(subclass)
      end
    end
  end

  context 'merging multiple hashes' do
    subject(:mash) { described_class.new(model: 'Honda') }

    it 'merges multiple hashes and mashes passed to #merge' do
      first_hash = { model: 'Ford' }
      second_hash = { model: 'DeLorean' }
      expect(mash.merge(first_hash, second_hash)).to eq('model' => 'DeLorean')
    end
  end

  describe '#except' do
    subject(:mash) { described_class.new(a: 'A', b: 'B') }

    it 'return a Hashie::Mash' do
      expect(mash.except(:b)).to be_a(described_class)
    end

    it 'excludes keys' do
      expect(mash.except(:b)).to eq('a' => 'A')
    end
  end

  context 'when serialized' do
    let(:child) { described_class.new(name: 'child') }
    let(:source) do
      described_class.new(
        name: 'parent', child: child, entries: [nil, false, true, 42, 1.5, child]
      )
    end

    %i[yaml marshal].each do |serializer|
      context "through #{serializer}" do
        let(:recovered) do
          if serializer == :yaml
            yaml = Psych.dump(source)
            # Load only trusted YAML generated by this test.
            Psych.respond_to?(:unsafe_load) ? Psych.unsafe_load(yaml) : Psych.load(yaml)
          else
            Marshal.load(Marshal.dump(source))
          end
        end

        it 'preserves classes and values at every level' do
          expect(recovered).to be_an_instance_of(described_class)
          expect(recovered).to eq source
          expect(recovered[:child]).to be_an_instance_of(described_class)
          expect(recovered[:child][:name]).to eq 'child'
          expect(recovered[:entries].last).to be_an_instance_of(described_class)
          expect(recovered[:entries].last[:name]).to eq 'child'
        end

        it 'creates independent objects and nested containers' do
          expect(recovered).not_to equal(source)
          expect(recovered[:child]).not_to equal(source[:child])
          expect(recovered[:entries]).not_to equal(source[:entries])
          recovered[:child][:name] = 'changed'
          recovered[:entries] << 'added'

          expect(source[:child][:name]).to eq 'child'
          expect(source[:entries].size).to eq 6
        end

        it 'preserves method access' do
          expect(recovered.name).to eq 'parent'
          expect(recovered.child.name).to eq 'child'
        end
      end
    end
  end
end
