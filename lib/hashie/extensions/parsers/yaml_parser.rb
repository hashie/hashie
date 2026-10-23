# frozen_string_literal: true

require 'yaml'
require 'pathname'

module Hashie
  module Extensions
    module Parsers
      # Parses YAML without evaluating ERB templates.
      class YamlParser
        def initialize(file_path, options = {})
          @content = File.read(file_path)
          @file_path = file_path.is_a?(Pathname) ? file_path.to_s : file_path
          @options = options
        end

        def perform
          yaml_safe_load(@content)
        end

        def self.perform(file_path, options = {})
          new(file_path, options).perform
        end

        private

        def yaml_safe_load(content)
          YAML.safe_load(
            content,
            permitted_classes: @options.fetch(:permitted_classes) { [] },
            permitted_symbols: @options.fetch(:permitted_symbols) { [] },
            aliases: @options.fetch(:aliases, true)
          )
        end
      end
    end
  end
end
