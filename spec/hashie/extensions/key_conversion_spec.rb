# frozen_string_literal: true

require 'spec_helper'
require 'support/module_context'

describe Hashie::Extensions::KeyConversion do
  include_context 'included hash module'

  it { is_expected.to respond_to(:stringify_keys) }
  it { is_expected.to respond_to(:stringify_keys!) }

  it { is_expected.to respond_to(:symbolize_keys) }
  it { is_expected.to respond_to(:symbolize_keys!) }
end
