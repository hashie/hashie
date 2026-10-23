# frozen_string_literal: true

require 'ripper'
require 'yard'
require 'rspec/core'
require 'rspec/expectations'
require 'hashie'

# Runs public API documentation examples using RSpec equality assertions.
module DocumentationExamples
  FILES = Dir['lib/**/*.rb'].freeze
  RAILS_FILES = %w[lib/hashie/railtie.rb lib/hashie/extensions/active_support/core_ext/hash.rb].freeze

  def self.evaluate(source, file, line)
    # A fresh namespace keeps class definitions and local variables independent.
    Module.new do
      extend RSpec::Matchers
    end.module_eval(asserted_source(source), file, line)
  end

  def self.asserted_source(source)
    lines = source.lines
    assertions = inline_assertions(source)
    raise ArgumentError, 'each example needs an inline # => assertion' if assertions.empty?

    assertions.each do |position, expected|
      index, column = position
      expression = lines[index - 1].byteslice(0, column).strip
      lines[index - 1] = assertion_source(expression, expected)
    end
    lines.join
  end

  def self.inline_assertions(source)
    Ripper.lex(source).filter_map do |position, type, text|
      next unless type == :on_comment && (match = text.match(/\A#\s*=>\s*(.+)/))

      [position, match[1].strip]
    end
  end

  def self.assertion_source(expression, expected)
    raise ArgumentError, 'expected an expression before # =>' if expression.empty?

    "expect(#{expression}).to eq(#{expected})\n"
  end

  def self.examples_for(files)
    YARD::Registry.clear
    # Parse umbrella namespace documentation after files that reopen it.
    YARD.parse(files.reject { |file| file == 'lib/hashie.rb' } + files.select { |file| file == 'lib/hashie.rb' })
    objects = YARD::Registry.all
    missing = objects.select { |object| public_api?(object) && object.tags(:example).empty? }
    raise ArgumentError, "public APIs missing executable examples:\n`#{missing.map(&:path).sort.join("\n")}`" unless missing.empty?

    objects.flat_map do |object|
      object.tags(:example).map { |example| [object, example] }
    end
  end

  def self.public_api?(object)
    return false unless %i[class module method].include?(object.type) && object.visibility == :public && object.file

    current = object
    until current.root?
      return false if current.has_tag?(:private) || current.tag(:api)&.text == 'private' || current.docstring.to_s.strip == ':nodoc:'

      current = current.parent
    end
    true
  end

  def self.run(files, rails: false)
    examples = examples_for(files)
    raise ArgumentError, 'no documentation examples found' if examples.empty?

    puts "Public API coverage: #{YARD::Registry.all.count { |object| public_api?(object) }} objects, 0 missing examples"
    examples = examples.select { |object, _example| RAILS_FILES.include?(object.file) == rails } if files == FILES
    raise ArgumentError, 'no documentation examples found for this environment' if examples.empty?

    define_specs(examples)
    RSpec::Core::Runner.run([])
  end

  def self.define_specs(examples)
    RSpec.describe 'YARD documentation examples' do
      examples.each do |object, example|
        it "#{object.path}: #{example.name}" do
          DocumentationExamples.evaluate(example.text, object.file, object.line)
        end
      end
    end
  end
end
