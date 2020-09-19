require 'spec_helper'

describe Hashie::Extensions::Dash::PredefinedValues do
  let(:extended_dash) do
    Class.new(Hashie::Dash) do
      include Hashie::Extensions::Dash::PredefinedValues

      property :gender, values: %i[male female prefer_not_to_say]
      property :age, values: (0..150)
    end
  end

  it 'allows value within the predefined list' do
    valid_dash = extended_dash.new(gender: :male)
    expect(valid_dash.gender).to eq(:male)
  end

  it 'rejects value outside the predefined list' do
    expect { extended_dash.new(gender: :unicorn) }
      .to raise_error(ArgumentError, %(Invalid value for property 'gender'))
  end

  it 'accepts a range for predefined list' do
    expect { extended_dash.new(age: -1) }
      .to raise_error(ArgumentError, %(Invalid value for property 'age'))
  end

  it 'allows property to be nil' do
    expect { extended_dash.new }
      .not_to raise_error
  end

  it 'rejects non array or range for predefined list' do
    expect do
      class DashWithUnsupportedValueType < Hashie::Dash
        include Hashie::Extensions::Dash::PredefinedValues

        property :name, values: -> { :foo }
      end
    end.to raise_error(ArgumentError, %(`values` accepts an Array or a Range.))
  end

  let(:subclass) do
    Class.new(extended_dash) do
      property :language, values: %i[ruby javascript]
    end
  end

  it 'passes property predefined list to subclasses' do
    expect { subclass.new(gender: :unicorn) }
      .to raise_error(ArgumentError, %(Invalid value for property 'gender'))
  end

  it 'allows subclass to define predefined list' do
    expect { subclass.new(language: :ruby) }
      .not_to raise_error
  end
end
