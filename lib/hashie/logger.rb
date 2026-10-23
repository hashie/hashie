# frozen_string_literal: true

require 'logger'

module Hashie
  # The logger that Hashie uses for reporting errors.
  #
  # @return [Logger]
  def self.logger
    @logger ||= Logger.new($stdout)
  end

  # Sets the logger that Hashie uses for reporting errors.
  #
  # @param logger [Logger] The logger to set as Hashie's logger.
  # @return [void]
  def self.logger=(logger)
    @logger = logger
  end
end
