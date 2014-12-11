require 'spec_helper'
require 'psych'

describe Hashie::Extensions::Dash::PsychSerialization do
  class DashWithSerialization < Hashie::Dash
    include Hashie::Extensions::Dash::PsychSerialization
    property :name, required: true
    property :child
  end

  it "serializes and deserializes with Psych" do
    child = DashWithSerialization.new(name: 'child')
    instance = DashWithSerialization.new(name: 'dash', child: child)

    instance_yaml = Psych.dump(instance)
    recovered_instance = Psych.load(instance_yaml)

    expect(recovered_instance).to eq instance
    expect(recovered_instance.child).to eq child
  end
end
