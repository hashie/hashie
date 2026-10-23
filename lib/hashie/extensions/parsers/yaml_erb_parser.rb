# frozen_string_literal: true

require 'erb'
require 'hashie/extensions/parsers/yaml_parser'

module Hashie
  module Extensions
    module Parsers
      # Parses YAML after evaluating ERB templates.
      class YamlErbParser < YamlParser
        def perform
          template = ERB.new(@content)
          template.filename = @file_path
          yaml_safe_load(template.result)
        end
      end
    end
  end
end
