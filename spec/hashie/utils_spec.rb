# frozen_string_literal: true

require 'spec_helper'

def a_method_to_match_against
  'Hello world!'
end

RSpec.describe Hashie::Utils do
  describe '.method_information' do
    it 'states the module or class that a native method was defined in' do
      bound_method = method(:object_id)

      message = described_class.method_information(bound_method)

      expect(message).to match('Kernel')
    end

    it 'states the line a Ruby method was defined at' do
      bound_method = method(:a_method_to_match_against)

      message = described_class.method_information(bound_method)

      expect(message).to match('spec/hashie/utils_spec.rb')
    end
  end

  describe '.safe_dup' do
    it 'returns the same object for values that cannot be duplicated' do
      expect(described_class.safe_dup(1)).to eq(1)
      expect(described_class.safe_dup(true)).to be(true)
      expect(described_class.safe_dup(false)).to be(false)
      expect(described_class.safe_dup(nil)).to be_nil
      expect(described_class.safe_dup(:sym)).to eq(:sym)
      expect(described_class.safe_dup(1r)).to eq(1r)
      expect(described_class.safe_dup(1i)).to eq(1i)
      expect(described_class.safe_dup(method(:object_id))).to eq(method(:object_id))
    end

    it 'duplicates other values' do
      value = 'hello'

      expect(described_class.safe_dup(value)).to eq(value)
      expect(described_class.safe_dup(value)).not_to be(value)
    end
  end

  describe 'a_method_to_match_against' do
    it 'returns a greeting' do
      expect(a_method_to_match_against).to eq('Hello world!')
    end
  end
end
