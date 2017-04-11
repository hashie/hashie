require 'yaml'
require 'erb'
module Hashie
  module Extensions
    module Parsers
      class YamlErbParser
        def initialize(file_path)
          @content = File.read(file_path)
          @file_path = file_path.is_a?(Pathname) ? file_path.to_s : file_path
        end

        def perform
          template = ERB.new(@content)
          @file_path = @file_path.to_s if @file_path.respond_to? :to_s
          template.filename = @file_path
          YAML.load template.result
        end

        def self.perform(file_path)
          new(file_path).perform
        end
      end
    end
  end
end
