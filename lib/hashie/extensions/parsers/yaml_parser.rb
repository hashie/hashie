# frozen_string_literal: true

require 'yaml'
require 'pathname'

module Hashie
  module Extensions
    module Parsers
      # Parses YAML without evaluating ERB templates.
      #
      # @example
      #   require 'tempfile'
      #   file = Tempfile.new(['hashie-example', '.yml'], '.')
      #   begin
      #     file.write("name: Ada\n")
      #     file.close
      #     Hashie::Extensions::Parsers::YamlParser.perform(file.path) # => {'name' => 'Ada'}
      #   ensure
      #     file.close!
      #   end
      class YamlParser
        # @example Read a Pathname and retain parsing options
        #   require 'tempfile'
        #   file = Tempfile.new(['hashie-example', '.yml'], '.')
        #   begin
        #     file.write("name: Ada\n")
        #     file.close
        #     parser = Hashie::Extensions::Parsers::YamlParser.new(Pathname.new(file.path), aliases: false)
        #     parser.perform # => {'name' => 'Ada'}
        #   ensure
        #     file.close!
        #   end
        def initialize(file_path, options = {})
          @content = File.read(file_path)
          @file_path = file_path.is_a?(Pathname) ? file_path.to_s : file_path
          @options = options
        end

        # @example Leave ERB untouched when loading YAML
        #   require 'tempfile'
        #   file = Tempfile.new(['hashie-example', '.yml'], '.')
        #   begin
        #     file.write("value: <%= 1 + 2 %>\n")
        #     file.close
        #     parser = Hashie::Extensions::Parsers::YamlParser.new(file.path)
        #     parser.perform # => {'value' => '<%= 1 + 2 %>'}
        #   ensure
        #     file.close!
        #   end
        def perform
          _yaml_safe_load(@content)
        end

        # @example Load YAML in one step
        #   require 'tempfile'
        #   file = Tempfile.new(['hashie-example', '.yml'], '.')
        #   begin
        #     file.write("count: 3\n")
        #     file.close
        #     Hashie::Extensions::Parsers::YamlParser.perform(file.path, aliases: false) # => {'count' => 3}
        #   ensure
        #     file.close!
        #   end
        def self.perform(file_path, options = {})
          new(file_path, options).perform
        end

        private

        def _yaml_safe_load(content)
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
