# frozen_string_literal: true

require 'rubygems'
require 'bundler'
Bundler.setup

Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.exclude_pattern = 'spec/integration/**/*_spec.rb'
end

require 'rubocop/rake_task'
RuboCop::RakeTask.new(:rubocop)
if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.2')
  RuboCop::RakeTask.new(:rubocop_exception_messages) do |task|
    task.patterns = ['lib/**/*.rb', 'spec/**/*.rb']
    task.options = ['--config', '.rubocop_exception_messages.yml']
  end
  task rubocop: :rubocop_exception_messages
end

require_relative 'spec/support/integration_specs'
task :integration_specs do
  next if ENV['CI']

  status_codes = []
  handler = lambda do |status_code|
    status_codes << status_code unless status_code.zero?
  end

  run_all_integration_specs(handler: handler, logger: ->(msg) { puts msg })

  if status_codes.any?
    warn "#{status_codes.size} integration test(s) failed"
    exit status_codes.last
  end
end

task default: %i[rubocop spec integration_specs]
