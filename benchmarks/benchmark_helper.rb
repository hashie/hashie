# frozen_string_literal: true

require 'json'
require 'logger'

REPOSITORY = JSON.parse(File.read(File.join(__dir__, 'fixtures', 'repository.json'))).freeze

def repository_attributes(*names)
  REPOSITORY.slice(*names.map(&:to_s)).transform_keys(&:to_sym).freeze
end

# Keep collision checks without timing log output.
Hashie.logger = Logger.new(nil)
