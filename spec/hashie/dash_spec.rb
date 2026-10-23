# frozen_string_literal: true

require 'spec_helper'

Hashie::Hash.class_eval do
  def self.inherited(klass)
    klass.instance_variable_set('@inheritance_test', true)
  end
end

class DashTest < Hashie::Dash
  property :first_name, required: true
  property :email
  property :count, default: 0
end

class DashTestDefaultProc < Hashie::Dash
  property :fields, default: -> { [] }
end

class DashNoRequiredTest < Hashie::Dash
  property :first_name
  property :email
  property :count, default: 0
end

class DashWithCoercion < Hashie::Dash
  include Hashie::Extensions::Coercion

  property :person
  property :city

  coerce_key :person, ::DashNoRequiredTest
end

class PropertyBangTest < Hashie::Dash
  property :important!
end

class SubclassedTest < DashTest
  property :last_name, required: true
end

class RequiredMessageTest < DashTest
  property :first_name, required: true, message: 'must be set'
end

class DashDefaultTest < Hashie::Dash
  property :aliases, default: ['Snake']
end

class DeferredTest < Hashie::Dash
  property :created_at, default: proc { Time.now }
end

class DeferredWithSelfTest < Hashie::Dash
  property :created_at, default: -> { Time.now }
  property :updated_at, default: ->(test) { test.created_at }
end

describe DashTestDefaultProc do
  it 'to_json behaves correctly with default proc' do
    object = described_class.new
    expect(object.to_json).to eq '{"fields":[]}'
  end
end

describe DashTest do
  def property_required_error(property)
    [ArgumentError, "the property `#{property}` is required for `#{subject.class.name}`"]
  end

  def property_required_custom_error(property)
    [ArgumentError, "the property `#{property}` must be set"]
  end

  def property_message_without_required_error
    [ArgumentError, 'the :message option should be used with :required option']
  end

  def no_property_error(property)
    [NoMethodError, "the property `#{property}` is not defined for `#{subject.class.name}`"]
  end

  subject { described_class.new(first_name: 'Bob', email: 'bob@example.com') }

  let(:required_message) { RequiredMessageTest.new(first_name: 'Bob') }

  it('subclasses Hashie::Hash') { is_expected.to respond_to(:to_mash) }

  describe '#to_s' do
    subject { super().to_s }

    it { is_expected.to eq '#<DashTest count=0 email="bob@example.com" first_name="Bob">' }
  end

  it 'lists all set properties in inspect' do
    subject.first_name = 'Bob'
    subject.email = 'bob@example.com'
    expect(subject.inspect).to eq '#<DashTest count=0 email="bob@example.com" first_name="Bob">'
  end

  describe '#count' do
    subject { super().count }

    it { is_expected.to be_zero }
  end

  it { is_expected.to respond_to(:first_name) }
  it { is_expected.to respond_to(:first_name=) }
  it { is_expected.not_to respond_to(:nonexistent) }

  it 'errors out for a non-existent property' do
    expect { subject['nonexistent'] }.to raise_error(*no_property_error('nonexistent'))
  end

  it 'errors out when attempting to set a required property to nil' do
    expect { subject.first_name = nil }.to raise_error(*property_required_error('first_name'))
  end

  it 'errors out when message added to not required property' do
    expect do
      class DashMessageOptionWithoutRequiredTest < Hashie::Dash
        property :first_name, message: 'is required.'
      end
    end.to raise_error(*property_message_without_required_error)

    expect do
      class DashMessageOptionWithoutRequiredTest < Hashie::Dash
        property :first_name, required: false, message: 'is required.'
      end
    end.to raise_error(*property_message_without_required_error)
  end

  context 'writing to properties' do
    it 'fails writing a required property to nil' do
      expect { subject.first_name = nil }.to raise_error(*property_required_error('first_name'))
      expect { required_message.first_name = nil }
        .to raise_error(*property_required_custom_error('first_name'))
    end

    it 'fails writing a required property to nil using []=' do
      expect { subject[:first_name] = nil }.to raise_error(*property_required_error('first_name'))
      expect { required_message[:first_name] = nil }
        .to raise_error(*property_required_custom_error('first_name'))
    end

    it 'fails writing to a non-existent property using []=' do
      expect { subject['nonexistent'] = 123 }.to raise_error(*no_property_error('nonexistent'))
    end

    it 'works for an existing property using []=' do
      subject[:first_name] = 'Bob'
      expect(subject[:first_name]).to eq 'Bob'
      expect { subject['first_name'] }.to raise_error(*no_property_error('first_name'))
    end

    it 'works for an existing property using a method call' do
      subject.first_name = 'Franklin'
      expect(subject.first_name).to eq 'Franklin'
    end
  end

  context 'reading from properties' do
    it 'fails reading from a non-existent property using []' do
      expect { subject['nonexistent'] }.to raise_error(*no_property_error('nonexistent'))
    end

    it 'is able to retrieve properties through blocks' do
      subject[:first_name] = 'Aiden'
      value = nil
      subject.[](:first_name) { |v| value = v }
      expect(value).to eq 'Aiden'
    end

    it 'is able to retrieve properties through blocks with method calls' do
      subject[:first_name] = 'Frodo'
      value = nil
      subject.first_name { |v| value = v }
      expect(value).to eq 'Frodo'
    end

    it 'evaluates a Proc value stored directly on a property when read' do
      subject[:first_name] = proc { 'Zorro' }
      expect(subject[:first_name]).to eq 'Zorro'
    end
  end

  context 'reading from deferred properties' do
    it 'evaluates proc after initial read' do
      expect(DeferredTest.new[:created_at]).to be_instance_of(Time)
    end

    it 'does not evaluate proc after subsequent reads' do
      deferred = DeferredTest.new
      created_at = deferred[:created_at]
      expect(deferred[:created_at]).to equal(created_at)
    end
  end

  context 'reading from a deferred property based on context' do
    it 'provides the current hash as context for evaluation' do
      deferred = DeferredWithSelfTest.new
      created_at = deferred[:created_at]
      expect(deferred[:created_at]).to equal(created_at)
      expect(deferred[:updated_at]).to equal(created_at)
    end
  end

  context 'converting from a Mash' do
    class ConvertingFromMash < Hashie::Dash
      property :property, required: true
    end

    context 'without keeping the original keys' do
      let(:mash) { Hashie::Mash.new(property: 'test') }

      it 'does not pick up the property from the stringified key' do
        expect { ConvertingFromMash.new(mash) }.to raise_error(NoMethodError)
      end
    end

    context 'when keeping the original keys' do
      class KeepingMash < Hashie::Mash
        include Hashie::Extensions::Mash::KeepOriginalKeys
      end

      let(:mash) { KeepingMash.new(property: 'test') }

      it 'picks up the property from the original key' do
        expect { ConvertingFromMash.new(mash) }.not_to raise_error
      end
    end
  end

  describe '#new' do
    it 'fails with non-existent properties' do
      expect { described_class.new(bork: '') }.to raise_error(*no_property_error('bork'))
    end

    it 'sets properties that it is able to' do
      obj = described_class.new first_name: 'Michael'
      expect(obj.first_name).to eq 'Michael'
    end

    it 'accepts nil' do
      expect { DashNoRequiredTest.new(nil) }.not_to raise_error
    end

    it 'accepts block to define a global default' do
      obj = described_class.new { |_, key| key.to_s.upcase }
      expect(obj.first_name).to eq 'FIRST_NAME'
      expect(obj.count).to be_zero
    end

    it 'fails when required values are missing' do
      expect { described_class.new }.to raise_error(*property_required_error('first_name'))
    end

    it 'does not overwrite default values' do
      obj1 = DashDefaultTest.new
      obj1.aliases << 'El Rey'
      obj2 = DashDefaultTest.new
      expect(obj2.aliases).not_to include 'El Rey'
    end
  end

  describe '#merge' do
    it 'creates a new instance of the Dash' do
      new_dash = subject.merge(first_name: 'Robert')
      expect(subject.object_id).not_to eq new_dash.object_id
    end

    it 'merges the given hash' do
      new_dash = subject.merge(first_name: 'Robert', email: 'robert@example.com')
      expect(new_dash.first_name).to eq 'Robert'
      expect(new_dash.email).to eq 'robert@example.com'
    end

    it 'fails with non-existent properties' do
      expect { subject.merge(middle_name: 'James') }
        .to raise_error(*no_property_error('middle_name'))
    end

    it 'errors out when attempting to set a required property to nil' do
      expect { subject.merge(first_name: nil) }
        .to raise_error(*property_required_error('first_name'))
    end

    context 'given a block' do
      it "sets merged key's values to the block's return value" do
        expect(subject.merge(first_name: 'Jim') do |key, oldval, newval|
          "#{key}: #{newval} #{oldval}"
        end.first_name).to eq 'first_name: Jim Bob'
      end
    end
  end

  describe '#merge!' do
    it 'modifies the existing instance of the Dash' do
      original_dash = subject.merge!(first_name: 'Robert')
      expect(subject.object_id).to eq original_dash.object_id
    end

    it 'merges the given hash' do
      subject.merge!(first_name: 'Robert', email: 'robert@example.com')
      expect(subject.first_name).to eq 'Robert'
      expect(subject.email).to eq 'robert@example.com'
    end

    it 'fails with non-existent properties' do
      expect { subject.merge!(middle_name: 'James') }.to raise_error(NoMethodError)
    end

    it 'errors out when attempting to set a required property to nil' do
      expect { subject.merge!(first_name: nil) }.to raise_error(ArgumentError)
    end

    context 'given a block' do
      it "sets merged key's values to the block's return value" do
        expect(subject.merge!(first_name: 'Jim') do |key, oldval, newval|
          "#{key}: #{newval} #{oldval}"
        end.first_name).to eq 'first_name: Jim Bob'
      end
    end
  end

  describe 'properties' do
    it 'lists defined properties' do
      expect(described_class.properties).to eq Set.new(%i[first_name email count])
    end

    it 'checks if a property exists' do
      expect(described_class).to be_property(:first_name)
      expect(described_class).not_to be_property('first_name')
    end

    it 'checks if a property is required' do
      expect(described_class).to be_required(:first_name)
      expect(described_class).not_to be_required('first_name')
    end

    it 'doesnt include property from subclass' do
      expect(described_class).not_to be_property(:last_name)
    end

    it 'lists declared defaults' do
      expect(described_class.defaults).to eq(count: 0)
    end

    it 'allows properties that end in bang' do
      expect(PropertyBangTest).to be_property(:important!)
    end
  end

  describe '#replace' do
    before { subject.replace(first_name: 'Cain') }

    it 'return self' do
      expect(subject.replace(email: 'bar').object_id).to eq subject.object_id
    end

    it 'sets all specified keys to their corresponding values' do
      expect(subject.first_name).to eq 'Cain'
    end

    it 'leaves only specified keys and keys with default values' do
      expect(subject.keys.sort_by(&:to_s)).to eq %i[count first_name]
      expect(subject.email).to be_nil
      expect(subject.count).to eq 0
    end

    context 'when replacing keys with default values' do
      before { subject.replace(count: 3) }

      it 'sets all specified keys to their corresponding values' do
        expect(subject.count).to eq 3
      end
    end
  end

  describe '#update_attributes!(params)' do
    let(:params) { { first_name: 'Alice', email: 'alice@example.com' } }

    context 'when there is coercion' do
      subject { DashWithCoercion.new(params_before) }

      let(:params_before) do
        { city: 'nyc', person: { first_name: 'Bob', email: 'bob@example.com' } }
      end
      let(:params_after) do
        { city: 'sfo', person: { first_name: 'Alice', email: 'alice@example.com' } }
      end

      it 'update the attributes' do
        expect(subject.person.first_name).to eq params_before[:person][:first_name]
        subject.update_attributes!(params_after)
        expect(subject.person.first_name).to eq params_after[:person][:first_name]
      end
    end

    it 'update the attributes' do
      subject.update_attributes!(params)
      expect(subject.first_name).to eq params[:first_name]
      expect(subject.email).to eq params[:email]
      expect(subject.count).to eq subject.class.defaults[:count]
    end

    context 'when required property is update to nil' do
      let(:params) { { first_name: nil, email: 'alice@example.com' } }

      it 'raise an ArgumentError' do
        expect { subject.update_attributes!(params) }.to raise_error(ArgumentError)
      end
    end

    context 'when a default property is update to nil' do
      let(:params) { { count: nil, email: 'alice@example.com' } }

      it 'set the property back to the default value' do
        subject.update_attributes!(params)
        expect(subject.email).to eq params[:email]
        expect(subject.count).to eq subject.class.defaults[:count]
      end
    end

    context 'when a default value cannot be duped' do
      let(:klass) do
        Class.new(Hashie::Dash) do
          property :thing, default: Object.new.singleton_class
        end
      end

      it 'falls back to using the original default value' do
        instance = klass.new(thing: nil)
        instance.update_attributes!(thing: nil)
        expect(instance.thing).to eq klass.defaults[:thing]
      end
    end

    context 'codependent attributes' do
      let(:codependent) do
        Class.new(Hashie::Dash) do
          property :a, required: -> { b.nil? }, message: 'is required if b is not set'
          property :b, required: -> { a.nil? }, message: 'is required if a is not set'
          property :c, default: -> { 'c' }
        end
      end

      it 'does not raise an error when only the first property is set' do
        expect { codependent.new(a: 'ant', b: nil) }.not_to raise_error
      end

      it 'does not raise an error when only the second property is set' do
        expect { codependent.new(a: nil, b: 'bat') }.not_to raise_error
      end

      it 'does not raise an error when both properties are set' do
        expect { codependent.new(a: 'ant', b: 'bat') }.not_to raise_error
      end

      it 'raises an error when neither property is set' do
        expect { codependent.new(a: nil, b: nil) }.to raise_error(ArgumentError)
      end

      context 'exporting nil values' do
        describe '#to_h' do
          it 'does not prune nil values' do
            expect(codependent.new(a: 'hi', b: nil).to_h).to eq(a: 'hi', b: nil, c: 'c')
            expect(codependent.new(a: 'hi', b: nil, c: nil).to_hash).to eq(a: 'hi', b: nil, c: 'c')
            expect(codependent.new(a: 'hi', b: nil).merge(c: nil).to_h).to(
              eq(a: 'hi', b: nil, c: nil)
            )
          end
        end

        describe '#to_hash' do
          it 'does not prune nil values' do
            expect(codependent.new(a: 'hi', b: nil).to_hash).to eq(a: 'hi', b: nil, c: 'c')
            expect(codependent.new(a: 'hi', b: nil, c: nil).to_hash).to eq(a: 'hi', b: nil, c: 'c')
            expect(codependent.new(a: 'hi', b: nil).merge(c: nil).to_hash).to(
              eq(a: 'hi', b: nil, c: nil)
            )
          end
        end

        describe '**' do
          # NOTE: This test is an implementation detail of MRI and may not hold for
          # other Ruby interpreters. But it's important to note in the test suite
          # because it can be surprising for people unfamiliar with the semantics of
          # double-splatting.
          #
          # For more information, see [this link][1]:
          #
          # [1]: https://github.com/hashie/hashie/issues/353#issuecomment-363294886
          it 'prunes nil values because they are not set in the dash' do
            dash = codependent.new(a: 'hi', b: nil)

            expect(**dash).to eq(a: 'hi', c: 'c')
          end
        end
      end
    end
  end
end

describe Hashie::Dash do
  before do
    @top = Class.new(described_class)
    @middle = Class.new(@top)
    @bottom = Class.new(@middle)
  end

  it 'reports empty properties when nothing defined' do
    expect(@top.properties).to be_empty
    expect(@top.defaults).to be_empty
  end

  it 'inherits properties downwards' do
    @top.property :echo
    expect(@middle.properties).to include(:echo)
    expect(@bottom.properties).to include(:echo)
  end

  it 'doesnt inherit properties upwards' do
    @middle.property :echo
    expect(@top.properties).not_to include(:echo)
    expect(@bottom.properties).to include(:echo)
  end

  it 'allows overriding a default on an existing property' do
    @top.property :echo
    @middle.property :echo, default: 123
    expect(@bottom.properties.to_a).to eq [:echo]
    expect(@bottom.new.echo).to eq 123
  end

  it 'allows clearing an existing default' do
    @top.property :echo
    @middle.property :echo, default: 123
    @bottom.property :echo
    expect(@bottom.properties.to_a).to eq [:echo]
    expect(@bottom.new.echo).to be_nil
  end

  it 'allows nil defaults' do
    @bottom.property :echo, default: nil
    expect(@bottom.new).to have_key(:echo)
    expect(@bottom.new).not_to have_key('echo')
  end

  context 'exporting nil values' do
    let(:test) do
      Class.new(Hashie::Dash) do
        property :foo
        property :bar
      end
    end

    describe '#to_h' do
      it 'does not prune nil values' do
        expect(test.new(foo: 'hi', bar: nil).to_h).to eq(foo: 'hi', bar: nil)
      end
    end

    describe '#to_hash' do
      it 'does not prune nil values' do
        expect(test.new(foo: 'hi', bar: nil).to_hash).to eq(foo: 'hi', bar: nil)
      end
    end

    describe '**' do
      # NOTE: This test is an implementation detail of MRI and may not hold for
      # other Ruby interpreters. But it's important to note in the test suite
      # because it can be surprising for people unfamiliar with the semantics of
      # double-splatting.
      #
      # For more information, see [this link][1]:
      #
      # [1]: https://github.com/hashie/hashie/issues/353#issuecomment-363294886
      it 'prunes nil values because they are not set in the dash' do
        dash = test.new(foo: 'hi', bar: nil)

        expect(**dash).to eq(foo: 'hi')
      end
    end
  end

  describe '#deep_transform_keys' do
    subject(:dash) { test.new(foo_bar: 'bar', foo_baz: 'baz') }

    let(:test) do
      Class.new(Hashie::Dash) do
        property :foo_bar
        property :foo_baz, required: true
      end
    end

    it 'returns a plain Hash with transformed keys' do
      transformed = dash.deep_transform_keys(&:to_s)
      expect(transformed).to eq('foo_bar' => 'bar', 'foo_baz' => 'baz')
    end

    it 'deep transforms keys of nested hash values' do
      nested_test = Class.new(Hashie::Dash) do
        property :foo_bar
        property :foo_baz, required: true
      end
      dash = nested_test.new(foo_bar: { nested_key: 'value' }, foo_baz: 'baz')

      transformed = dash.deep_transform_keys(&:to_s)
      expect(transformed).to eq('foo_bar' => { 'nested_key' => 'value' }, 'foo_baz' => 'baz')
    end

    it 'does not raise when required properties are present' do
      expect { dash.deep_transform_keys(&:to_s) }.not_to raise_error
    end
  end
end

describe SubclassedTest do
  subject { described_class.new(first_name: 'Bob', last_name: 'McNob', email: 'bob@example.com') }

  describe '#count' do
    subject { super().count }

    it { is_expected.to be_zero }
  end

  it { is_expected.to respond_to(:first_name) }
  it { is_expected.to respond_to(:first_name=) }
  it { is_expected.to respond_to(:last_name) }
  it { is_expected.to respond_to(:last_name=) }

  it 'has one additional property' do
    expect(described_class).to be_property(:last_name)
  end

  it "didn't override superclass inheritance logic" do
    expect(described_class.instance_variable_get('@inheritance_test')).to be_truthy
  end
end

class ConditionallyRequiredTest < Hashie::Dash
  property :username
  property :password, required: -> { !username.nil? }, message: 'must be set, too'
end

describe ConditionallyRequiredTest do
  it 'does not allow a conditionally required property to be set to nil if required' do
    expect { described_class.new(username: 'bob.smith', password: nil) }
      .to raise_error(ArgumentError, 'the property `password` must be set, too')
  end

  it 'allows a conditionally required property to be set to nil if not required' do
    expect { described_class.new(username: nil, password: nil) }.not_to raise_error
  end

  it 'allows a conditionally required property to be set if required' do
    expect { described_class.new(username: 'bob.smith', password: '$ecure!') }
      .not_to raise_error
  end
end

class SymbolConditionallyRequiredTest < Hashie::Dash
  property :username
  property :password, required: :username_present?, message: 'must be set, too.'

  def username_present?
    !username.nil?
  end
end

describe SymbolConditionallyRequiredTest do
  it 'does not allow a conditionally required property to be set to nil if required via a symbol condition' do
    expect { described_class.new(username: 'bob.smith', password: nil) }
      .to raise_error(ArgumentError, 'the property `password` must be set, too.')
  end

  it 'allows a conditionally required property to be set to nil if not required via a symbol condition' do
    expect { described_class.new(username: nil, password: nil) }.not_to raise_error
  end
end

class MixedPropertiesTest < Hashie::Dash
  property :symbol
  property 'string'
end

describe MixedPropertiesTest do
  subject { described_class.new('string' => 'string', symbol: 'symbol') }

  it { is_expected.to respond_to('string') }
  it { is_expected.to respond_to(:symbol) }

  it 'property?' do
    expect(described_class).to be_property('string')
    expect(described_class).to be_property(:symbol)
  end

  it 'fetch' do
    expect(subject['string']).to eq('string')
    expect { subject[:string] }.to raise_error(NoMethodError)
    expect(subject[:symbol]).to eq('symbol')
    expect { subject['symbol'] }.to raise_error(NoMethodError)
  end

  it 'double define' do
    klass = Class.new(MixedPropertiesTest) do
      property 'symbol'
    end
    instance = klass.new(symbol: 'one', 'symbol' => 'two')
    expect(instance[:symbol]).to eq('one')
    expect(instance['symbol']).to eq('two')
  end

  it 'assign' do
    subject['string'] = 'updated'
    expect(subject['string']).to eq('updated')

    expect { subject[:string] = 'updated' }.to raise_error(NoMethodError)

    subject[:symbol] = 'updated'
    expect(subject[:symbol]).to eq('updated')

    expect { subject['symbol'] = 'updated' }.to raise_error(NoMethodError)
  end
end

context 'Dynamic Dash Class' do
  it 'define property' do
    klass       = Class.new(Hashie::Dash)
    my_property = 'my_property'
    my_orig     = my_property.dup

    klass.property(my_property)

    expect(my_property).to eq(my_orig)
  end
end

context 'with method access' do
  class DashWithMethodAccess < Hashie::Dash
    include Hashie::Extensions::IndifferentAccess
    include Hashie::Extensions::MethodQuery

    property :test
  end

  subject(:dash) { DashWithMethodAccess.new(test: 'value') }

  describe '#test' do
    subject { dash.test }

    it { is_expected.to eq('value') }
  end

  describe '#test?' do
    subject { dash.test? }

    it { is_expected.to be true }
  end
end

RSpec.describe Hashie::Dash do
  let(:test) do
    Class.new(Hashie::Dash) do
      property :description, default: ''
    end
  end

  it_behaves_like 'Dash default handling', :description
end

module SerializationFixtures
  class Dash < Hashie::Dash
    property :name, required: true
    property :child
    property :entries
  end
end

describe SerializationFixtures::Dash do
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

        it 'preserves required and declared property validation' do
          expect { recovered.name = nil }.to raise_error(ArgumentError)
          expect { recovered[:unknown] = 'value' }.to raise_error(NoMethodError)
        end
      end
    end
  end
end
