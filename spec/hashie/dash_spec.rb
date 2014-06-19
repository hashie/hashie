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

class DashDefaultTest < Hashie::Dash
  property :aliases, default: ['Snake']
end

class DeferredTest < Hashie::Dash
  property :created_at, default: proc { Time.now }
end

describe DashTest do
  def property_required_error(property)
    [ArgumentError, "The property '#{property}' is required for #{subject.class.name}."]
  end

  def no_property_error(property)
    [NoMethodError, "The property '#{property}' is not defined for #{subject.class.name}."]
  end

  subject { DashTest.new(first_name: 'Bob', email: 'bob@example.com') }

  it('subclasses Hashie::Hash') { should respond_to(:to_mash) }

  describe '#to_s' do
    subject { super().to_s }
    it { should eq '#<DashTest count=0 email="bob@example.com" first_name="Bob">' }
  end

  it 'lists all set properties in inspect' do
    subject.first_name = 'Bob'
    subject.email = 'bob@example.com'
    expect(subject.inspect).to eq '#<DashTest count=0 email="bob@example.com" first_name="Bob">'
  end

  describe '#count' do
    subject { super().count }
    it { should be_zero }
  end

  it { should respond_to(:first_name) }
  it { should respond_to(:first_name=) }
  it { should_not respond_to(:nonexistent) }

  it 'errors out for a non-existent property' do
    expect { subject['nonexistent'] }.to raise_error(*no_property_error('nonexistent'))
  end

  it 'errors out when attempting to set a required property to nil' do
    expect { subject.first_name = nil }.to raise_error(*property_required_error('first_name'))
  end

  context 'writing to properties' do
    it 'fails writing a required property to nil' do
      expect { subject.first_name = nil }.to raise_error(*property_required_error('first_name'))
    end

    it 'fails writing a required property to nil using []=' do
      expect { subject[:first_name] = nil }.to raise_error(*property_required_error('first_name'))
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
  end

  context 'reading from deferred properties' do
    it 'evaluates proc after initial read' do
      expect(DeferredTest.new[:created_at]).to be_instance_of(Time)
    end

    it 'does not evalute proc after subsequent reads' do
      deferred = DeferredTest.new
      expect(deferred[:created_at].object_id).to eq deferred[:created_at].object_id
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
      expect { DashTest.new }.to raise_error(*property_required_error('first_name'))
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
      expect { subject.merge(middle_name: 'James') }.to raise_error(*no_property_error('middle_name'))
    end

    it 'errors out when attempting to set a required property to nil' do
      expect { subject.merge(first_name: nil) }.to raise_error(*property_required_error('first_name'))
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
      expect(described_class.properties).to eq Set.new([:first_name, :email, :count])
    end

    it 'checks if a property exists' do
      expect(described_class.property?(:first_name)).to be_truthy
      expect(described_class.property?('first_name')).to be_falsy
    end

    it 'checks if a property is required' do
      expect(described_class.required?(:first_name)).to be_truthy
      expect(described_class.required?('first_name')).to be_falsy
    end

    it 'doesnt include property from subclass' do
      expect(described_class.property?(:last_name)).to be_falsy
    end

    it 'lists declared defaults' do
      expect(described_class.defaults).to eq(count: 0)
    end

    it 'allows properties that end in bang' do
      expect(PropertyBangTest.property?(:important!)).to be_truthy
    end
  end

  describe '#replace' do
    before { subject.replace(first_name: 'Cain') }

    it 'return self' do
      expect(subject.replace(email: 'bar').to_hash).to eq(email: 'bar', count: 0)
    end

    it 'sets all specified keys to their corresponding values' do
      expect(subject.first_name).to eq 'Cain'
    end

    it 'leaves only specified keys and keys with default values' do
      expect(subject.keys.sort_by { |key| key.to_s }).to eq [:count, :first_name]
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
      let(:params_before) { { city: 'nyc', person: { first_name: 'Bob', email: 'bob@example.com' } } }
      let(:params_after) { { city: 'sfo', person: { first_name: 'Alice', email: 'alice@example.com' } } }

      subject { DashWithCoercion.new(params_before) }

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
  end

end

describe Hashie::Dash, 'inheritance' do
  before do
    @top = Class.new(Hashie::Dash)
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
    expect(@bottom.new).to_not have_key('echo')
  end

end

describe SubclassedTest do
  subject { SubclassedTest.new(first_name: 'Bob', last_name: 'McNob', email: 'bob@example.com') }

  describe '#count' do
    subject { super().count }
    it { should be_zero }
  end

  it { should respond_to(:first_name) }
  it { should respond_to(:first_name=) }
  it { should respond_to(:last_name) }
  it { should respond_to(:last_name=) }

  it 'has one additional property' do
    expect(described_class.property?(:last_name)).to be_truthy
  end

  it "didn't override superclass inheritance logic" do
    expect(described_class.instance_variable_get('@inheritance_test')).to be_truthy
  end
end

class MixedPropertiesTest < Hashie::Dash
  property :symbol
  property 'string'
end

describe MixedPropertiesTest do
  subject { MixedPropertiesTest.new('string' => 'string', symbol: 'symbol') }

  it { should respond_to('string') }
  it { should respond_to(:symbol) }

  it 'property?' do
    expect(described_class.property?('string')).to be_truthy
    expect(described_class.property?(:symbol)).to be_truthy
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
