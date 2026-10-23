# frozen_string_literal: true

require 'spec_helper'

describe Hashie::Extensions::Dash::Coercion do
  class DashWithCoercion < Hashie::Dash
    include Hashie::Extensions::Dash::Coercion

    property :type, coerce: Symbol
  end

  it 'does the coercion of properties' do
    expect(DashWithCoercion.new(type: 'something')).to eq(type: :something)
  end

  context 'with a callable coercer' do
    let(:coercer) do
      Object.new.tap do |object|
        def object.call(value)
          value == 'true'
        end
      end
    end

    let(:dash_class) do
      callable = coercer
      Class.new(Hashie::Dash) do
        include Hashie::Extensions::Dash::Coercion

        property :enabled, coerce: callable
      end
    end

    it 'coerces initialization and property assignment' do
      dash = dash_class.new(enabled: 'true')
      expect(dash.enabled).to be(true)
      dash.enabled = 'false'
      expect(dash.enabled).to be(false)
    end

    it 'preserves nil without invoking the callable' do
      expect(coercer).not_to receive(:call)
      dash = dash_class.new
      dash.enabled = nil
      expect(dash.enabled).to be_nil
    end
  end
end
