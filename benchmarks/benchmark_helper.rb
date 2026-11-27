# frozen_string_literal: true

require 'hashie'
require 'json'
require 'logger'

REPOSITORY_JSON = File.read(File.join(__dir__, 'fixtures', 'repository.json')).freeze
REPOSITORY = JSON.parse(REPOSITORY_JSON).freeze

def repository_attributes(*names)
  REPOSITORY.slice(*names.map(&:to_s)).transform_keys(&:to_sym).freeze
end

# Keep collision checks without timing log output.
Hashie.logger = Logger.new(nil)
