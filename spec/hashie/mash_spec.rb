require 'spec_helper'
require 'delegate'

describe Hashie::Mash do
  subject { Hashie::Mash.new }

  it 'inherits from Hash' do
    subject.is_a?(Hash).should be_true
  end

  it 'sets hash values through method= calls' do
    subject.test = 'abc'
    subject['test'].should eq 'abc'
  end

  it 'retrieves set values through method calls' do
    subject['test'] = 'abc'
    subject.test.should eq 'abc'
  end

  it 'retrieves set values through blocks' do
    subject['test'] = 'abc'
    value = nil
    subject.[]('test') { |v| value = v }
    value.should eq 'abc'
  end

  it 'retrieves set values through blocks with method calls' do
    subject['test'] = 'abc'
    value = nil
    subject.test { |v| value = v }
    value.should eq 'abc'
  end

  it 'tests for already set values when passed a ? method' do
    subject.test?.should be_false
    subject.test = 'abc'
    subject.test?.should be_true
  end

  it 'returns false on a ? method if a value has been set to nil or false' do
    subject.test = nil
    subject.should_not be_test
    subject.test = false
    subject.should_not be_test
  end

  it 'makes all [] and []= into strings for consistency' do
    subject['abc'] = 123
    subject.key?('abc').should be_true
    subject['abc'].should eq 123
  end

  it 'has a to_s that is identical to its inspect' do
    subject.abc = 123
    subject.to_s.should eq subject.inspect
  end

  it 'returns nil instead of raising an error for attribute-esque method calls' do
    subject.abc.should be_nil
  end

  it 'returns the default value if set like Hash' do
    subject.default = 123
    subject.abc.should eq 123
  end

  it 'gracefully handles being accessed with arguments' do
    subject.abc('foobar').should eq nil
    subject.abc = 123
    subject.abc('foobar').should eq 123
  end

  it 'returns a Hashie::Mash when passed a bang method to a non-existenct key' do
    subject.abc!.is_a?(Hashie::Mash).should be_true
  end

  it 'returns the existing value when passed a bang method for an existing key' do
    subject.name = 'Bob'
    subject.name!.should eq 'Bob'
  end

  it 'returns a Hashie::Mash when passed an under bang method to a non-existenct key' do
    subject.abc_.is_a?(Hashie::Mash).should be_true
  end

  it 'returns the existing value when passed an under bang method for an existing key' do
    subject.name = 'Bob'
    subject.name_.should eq 'Bob'
  end

  it '#initializing_reader returns a Hashie::Mash when passed a non-existent key' do
    subject.initializing_reader(:abc).is_a?(Hashie::Mash).should be_true
  end

  it 'allows for multi-level assignment through bang methods' do
    subject.author!.name = 'Michael Bleigh'
    subject.author.should eq Hashie::Mash.new(name: 'Michael Bleigh')
    subject.author!.website!.url = 'http://www.mbleigh.com/'
    subject.author.website.should eq Hashie::Mash.new(url: 'http://www.mbleigh.com/')
  end

  it 'allows for multi-level under bang testing' do
    subject.author_.website_.url.should be_nil
    subject.author_.website_.url?.should eq false
    subject.author.should be_nil
  end

  it 'does not call super if id is not a key' do
    subject.id.should eq nil
  end

  it 'returns the value if id is a key' do
    subject.id = 'Steve'
    subject.id.should eq 'Steve'
  end

  it 'does not call super if type is not a key' do
    subject.type.should eq nil
  end

  it 'returns the value if type is a key' do
    subject.type = 'Steve'
    subject.type.should eq 'Steve'
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
        subject.first_name.should eq 'Michael'
        subject.details.email.should eq 'michael@intridea.com'
        subject.details.address.should eq 'Nowhere road'
        subject.details.city.should eq 'Imagineton'
      end

      it 'converts values only once' do
        class ConvertedMash < Hashie::Mash
        end

        rhs = ConvertedMash.new(email: 'foo@bar.com')
        subject.should_receive(:convert_value).exactly(1).times
        subject.deep_update(rhs)
      end

      it 'makes #update deep by default' do
        subject.update(details: { address: 'Fake street' }).should eql(subject)
        subject.details.address.should eq 'Fake street'
        subject.details.email.should eq 'michael@asf.com'
      end

      it 'clones before a #deep_merge' do
        duped = subject.deep_merge(details: { address: 'Fake street' })
        duped.should_not eql(subject)
        duped.details.address.should eq 'Fake street'
        subject.details.address.should eq 'Nowhere road'
        duped.details.email.should eq 'michael@asf.com'
      end

      it 'default #merge is deep' do
        duped = subject.merge(details: { email: 'michael@intridea.com' })
        duped.should_not eql(subject)
        duped.details.email.should eq 'michael@intridea.com'
        duped.details.address.should eq 'Nowhere road'
      end

      # http://www.ruby-doc.org/core-1.9.3/Hash.html#method-i-update
      it 'accepts a block' do
        duped = subject.merge(details: { address: 'Pasadena CA' }) { |key, oldv, newv| [oldv, newv].join(', ') }
        duped.details.address.should eq 'Nowhere road, Pasadena CA'
      end
    end

    describe 'shallow update' do
      it 'shallowly Hashie::Mash Hashie::Mashes and hashes together' do
        subject.shallow_update(details: {
                                 email: 'michael@intridea.com', city: 'Imagineton'
        }).should eql(subject)

        subject.first_name.should eq 'Michael'
        subject.details.email.should eq 'michael@intridea.com'
        subject.details.address.should be_nil
        subject.details.city.should eq 'Imagineton'
      end

      it 'clones before a #regular_merge' do
        duped = subject.shallow_merge(details: { address: 'Fake street' })
        duped.should_not eql(subject)
      end

      it 'default #merge is shallow' do
        duped = subject.shallow_merge(details: { address: 'Fake street' })
        duped.details.address.should eq 'Fake street'
        subject.details.address.should eq 'Nowhere road'
        duped.details.email.should be_nil
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
        subject.replace(foo: 'bar').to_hash.should eq('foo' => 'bar')
      end

      it 'sets all specified keys to their corresponding values' do
        subject.middle_name?.should be_true
        subject.details?.should be_true
        subject.middle_name.should eq 'Cain'
        subject.details.city?.should be_true
        subject.details.city.should eq 'Imagination'
      end

      it 'leaves only specified keys' do
        subject.keys.sort.should eq %w(details middle_name)
        subject.first_name?.should be_false
        subject.should_not respond_to(:first_name)
        subject.last_name?.should be_false
        subject.should_not respond_to(:last_name)
      end
    end

    describe 'delete' do
      it 'deletes with String key' do
        subject.delete('details')
        subject.details.should be_nil
        subject.should_not be_respond_to :details
      end

      it 'deletes with Symbol key' do
        subject.delete(:details)
        subject.details.should be_nil
        subject.should_not be_respond_to :details
      end
    end
  end

  it 'converts hash assignments into Hashie::Mashes' do
    subject.details = { email: 'randy@asf.com', address: { state: 'TX' } }
    subject.details.email.should eq 'randy@asf.com'
    subject.details.address.state.should eq 'TX'
  end

  it 'does not convert the type of Hashie::Mashes childs to Hashie::Mash' do
    class MyMash < Hashie::Mash
    end

    record = MyMash.new
    record.son = MyMash.new
    record.son.class.should eq MyMash
  end

  it 'does not change the class of Mashes when converted' do
    class SubMash < Hashie::Mash
    end

    record = Hashie::Mash.new
    son = SubMash.new
    record['submash'] = son
    record['submash'].should be_kind_of(SubMash)
  end

  it 'respects the class when passed a bang method for a non-existent key' do
    record = Hashie::Mash.new
    record.non_existent!.should be_kind_of(Hashie::Mash)

    class SubMash < Hashie::Mash
    end

    son = SubMash.new
    son.non_existent!.should be_kind_of(SubMash)
  end

  it 'respects the class when passed an under bang method for a non-existent key' do
    record = Hashie::Mash.new
    record.non_existent_.should be_kind_of(Hashie::Mash)

    class SubMash < Hashie::Mash
    end

    son = SubMash.new
    son.non_existent_.should be_kind_of(SubMash)
  end

  it 'respects the class when converting the value' do
    record = Hashie::Mash.new
    record.details = Hashie::Mash.new(email: 'randy@asf.com')
    record.details.should be_kind_of(Hashie::Mash)
  end

  it 'respects another subclass when converting the value' do
    record = Hashie::Mash.new

    class SubMash < Hashie::Mash
    end

    son = SubMash.new(email: 'foo@bar.com')
    record.details = son
    record.details.should be_kind_of(SubMash)
  end

  describe '#respond_to?' do
    it 'responds to a normal method' do
      Hashie::Mash.new.should be_respond_to(:key?)
    end

    it 'responds to a set key' do
      Hashie::Mash.new(abc: 'def').should be_respond_to(:abc)
    end

    it 'responds to a set key with a suffix' do
      %w(= ? ! _).each do |suffix|
        Hashie::Mash.new(abc: 'def').should be_respond_to(:"abc#{suffix}")
      end
    end

    it 'does not respond to an unknown key with a suffix' do
      %w(= ? ! _).each do |suffix|
        Hashie::Mash.new(abc: 'def').should_not be_respond_to(:"xyz#{suffix}")
      end
    end

    it 'does not respond to an unknown key without a suffix' do
      Hashie::Mash.new(abc: 'def').should_not be_respond_to(:xyz)
    end

    it 'does not respond to permitted?' do
      Hashie::Mash.new.should_not be_respond_to(:permitted?)
    end
  end

  context '#initialize' do
    it 'converts an existing hash to a Hashie::Mash' do
      converted = Hashie::Mash.new(abc: 123, name: 'Bob')
      converted.abc.should eq 123
      converted.name.should eq 'Bob'
    end

    it 'converts hashes recursively into Hashie::Mashes' do
      converted = Hashie::Mash.new(a: { b: 1, c: { d: 23 } })
      converted.a.is_a?(Hashie::Mash).should be_true
      converted.a.b.should eq 1
      converted.a.c.d.should eq 23
    end

    it 'converts hashes in arrays into Hashie::Mashes' do
      converted = Hashie::Mash.new(a: [{ b: 12 }, 23])
      converted.a.first.b.should eq 12
      converted.a.last.should eq 23
    end

    it 'converts an existing Hashie::Mash into a Hashie::Mash' do
      initial = Hashie::Mash.new(name: 'randy', address: { state: 'TX' })
      copy = Hashie::Mash.new(initial)
      initial.name.should eq copy.name
      initial.__id__.should_not eq copy.__id__
      copy.address.state.should eq 'TX'
      copy.address.state = 'MI'
      initial.address.state.should eq 'TX'
      copy.address.__id__.should_not eq initial.address.__id__
    end

    it 'accepts a default block' do
      initial = Hashie::Mash.new { |h, i| h[i] = [] }
      initial.default_proc.should_not be_nil
      initial.default.should be_nil
      initial.test.should eq []
      initial.test?.should be_true
    end

    it 'converts Hashie::Mashes within Arrays back to Hashes' do
      initial_hash = { 'a' => [{ 'b' => 12, 'c' => ['d' => 50, 'e' => 51] }, 23] }
      converted = Hashie::Mash.new(initial_hash)
      converted.to_hash['a'].first.is_a?(Hashie::Mash).should be_false
      converted.to_hash['a'].first.is_a?(Hash).should be_true
      converted.to_hash['a'].first['c'].first.is_a?(Hashie::Mash).should be_false
    end
  end

  describe '#fetch' do
    let(:hash) { { one: 1, other: false } }
    let(:mash) { Hashie::Mash.new(hash) }

    context 'when key exists' do
      it 'returns the value' do
        mash.fetch(:one).should eql(1)
      end

      it 'returns the value even if the value is falsy' do
        mash.fetch(:other).should eql(false)
      end

      context 'when key has other than original but acceptable type' do
        it 'returns the value' do
          mash.fetch('one').should eql(1)
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
          mash.fetch(:two, 8).should eql(8)
        end

        it 'returns default value even if it is falsy' do
          mash.fetch(:two, false).should eql(false)
        end
      end

      context 'with block given' do
        it 'returns default value' do
          mash.fetch(:two) do |key|
            'block default value'
          end.should eql('block default value')
        end
      end
    end
  end

  describe '#to_hash' do
    let(:hash) { { 'outer' => { 'inner' => 42 }, 'testing' => [1, 2, 3] } }
    let(:mash) { Hashie::Mash.new(hash) }

    it 'returns a standard Hash' do
      mash.to_hash.should be_a(::Hash)
    end

    it 'includes all keys' do
      mash.to_hash.keys.should eql(%w(outer testing))
    end

    it 'converts keys to symbols when symbolize_keys option is true' do
      mash.to_hash(symbolize_keys: true).keys.should include(:outer)
      mash.to_hash(symbolize_keys: true).keys.should_not include('outer')
    end

    it 'leaves keys as strings when symbolize_keys option is false' do
      mash.to_hash(symbolize_keys: false).keys.should include('outer')
      mash.to_hash(symbolize_keys: false).keys.should_not include(:outer)
    end

    it 'symbolizes keys recursively' do
      mash.to_hash(symbolize_keys: true)[:outer].keys.should include(:inner)
      mash.to_hash(symbolize_keys: true)[:outer].keys.should_not include('inner')
    end
  end
end
