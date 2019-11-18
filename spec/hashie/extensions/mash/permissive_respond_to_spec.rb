require 'spec_helper'

RSpec.describe Hashie::Extensions::Mash::PermissiveRespondTo do
  class PermissiveMash < Hashie::Mash
    include Hashie::Extensions::Mash::PermissiveRespondTo
  end

  it 'allows you to bind to unset getters' do
    mash = PermissiveMash.new(a: 1)
    other_mash = PermissiveMash.new(b: 2)

    expect { mash.method(:b) }.not_to raise_error
    expect(mash.method(:b).unbind.bind(other_mash).call).to eq 2
  end

  it 'works properly with SimpleDelegator' do
    delegator = Class.new(SimpleDelegator) do
      def initialize(hash)
        super(PermissiveMash.new(hash))
      end
    end

    foo = delegator.new(a: 1)

    expect(foo.a).to eq 1
    expect { foo.b }.not_to raise_error
  end

  context 'warnings' do
    include_context 'with a logger'

    it 'does not log a collision when setting normal keys' do
      PermissiveMash.new(a: 1)

      expect(logger_output).to be_empty
    end

    it 'logs a collision with a built-in method' do
      PermissiveMash.new(zip: 1)

      expect(logger_output).to match('PermissiveMash#zip defined in Enumerable')
    end
  end
end
