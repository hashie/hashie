require 'spec_helper'

def a_method_to_match_against
  'Hello world!'
end

RSpec.describe Hashie::Utils do
  describe '.method_information' do
    it 'states the module or class that a native method was defined in' do
      bound_method = method(:object_id)

      message = Hashie::Utils.method_information(bound_method)

      expect(message).to match('Kernel')
    end

    it 'states the line a Ruby method was defined at' do
      bound_method = method(:a_method_to_match_against)

      message = Hashie::Utils.method_information(bound_method)

      expect(message).to match('spec/hashie/utils_spec.rb')
    end
  end

  describe '.safe_dup' do
    it 'returns the same object for values that cannot be duplicated' do
      expect(Hashie::Utils.safe_dup(1)).to eq(1)
      expect(Hashie::Utils.safe_dup(true)).to eq(true)
      expect(Hashie::Utils.safe_dup(false)).to eq(false)
      expect(Hashie::Utils.safe_dup(nil)).to be_nil
      expect(Hashie::Utils.safe_dup(:sym)).to eq(:sym)
      expect(Hashie::Utils.safe_dup(1r)).to eq(1r)
      expect(Hashie::Utils.safe_dup(1i)).to eq(1i)
      expect(Hashie::Utils.safe_dup(method(:object_id))).to eq(method(:object_id))
    end

    it 'duplicates other values' do
      value = 'hello'

      expect(Hashie::Utils.safe_dup(value)).to eq(value)
      expect(Hashie::Utils.safe_dup(value)).not_to be(value)
    end
  end

  describe 'a_method_to_match_against' do
    it 'returns a greeting' do
      expect(a_method_to_match_against).to eq('Hello world!')
    end
  end
end
