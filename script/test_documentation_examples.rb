# frozen_string_literal: true

require_relative 'documentation_examples'

rails = !ARGV.delete('--rails').nil?
exit DocumentationExamples.run(ARGV.empty? ? DocumentationExamples::FILES : ARGV.dup, rails: rails)
