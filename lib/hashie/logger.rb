# frozen_string_literal: true

require 'logger'

module Hashie
  # The logger that Hashie uses for reporting errors.
  #
  # @return [Logger]
  #
  # @example Obtain the logger used for warnings
  #   Hashie.logger.respond_to?(:warn) # => true
  def self.logger
    @logger ||= Logger.new($stdout)
  end

  # Sets the logger that Hashie uses for reporting errors.
  #
  # @param logger [Logger] The logger to set as Hashie's logger.
  # @return [void]
  #
  # @example Temporarily capture warnings
  #   require 'stringio'
  #   original = Hashie.logger
  #   begin
  #     output = StringIO.new
  #     Hashie.logger = Logger.new(output)
  #     Hashie.logger.warn('example warning')
  #     output.string.include?('example warning') # => true
  #   ensure
  #     Hashie.logger = original
  #   end
  def self.logger=(logger)
    @logger = logger
  end
end
