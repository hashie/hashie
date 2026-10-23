# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hashie do
  describe '.logger' do
    include_context 'with a logger'

    it 'is available via an accessor' do
      described_class.logger.info('Fee fi fo fum')

      expect(logger_output).to match('Fee fi fo fum')
    end
  end
end
