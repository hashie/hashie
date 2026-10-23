# frozen_string_literal: true

require 'erb'
require 'hashie/extensions/parsers/yaml_parser'

module Hashie
  module Extensions
    module Parsers
      # Parses YAML after evaluating ERB templates.
      #
      # @example
      #   require 'tempfile'
      #   file = Tempfile.new(['hashie-example', '.yml'], '.')
      #   begin
      #     file.write("count: <%= 1 + 2 %>\n")
      #     file.close
      #     Hashie::Extensions::Parsers::YamlErbParser.perform(file.path) # => {'count' => 3}
      #   ensure
      #     file.close!
      #   end
      class YamlErbParser < YamlParser
        # @example Evaluate ERB before safely loading YAML
        #   require 'tempfile'
        #   file = Tempfile.new(['hashie-example', '.yml'], '.')
        #   begin
        #     file.write("count: <%= 2 * 3 %>\n")
        #     file.close
        #     parser = Hashie::Extensions::Parsers::YamlErbParser.new(file.path)
        #     parser.perform # => {'count' => 6}
        #   ensure
        #     file.close!
        #   end
        def perform
          template = ERB.new(@content)
          template.filename = @file_path
          yaml_safe_load(template.result)
        end
      end
    end
  end
end
