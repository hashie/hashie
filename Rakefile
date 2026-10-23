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

namespace :docs do
  desc 'Validate executable YARD examples and public API documentation coverage'
  task :examples do
    ruby '-Ilib', 'script/test_documentation_examples.rb'
  end
end

require 'rubocop/rake_task'
RuboCop::RakeTask.new(:rubocop)
if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.2')
  RuboCop::RakeTask.new(:rubocop_exception_messages) do |task|
    task.patterns = ['lib/**/*.rb', 'spec/**/*.rb']
    task.options = [
      '--only',
      'ExceptionMessages/Casing,ExceptionMessages/Punctuation,' \
      'ExceptionMessages/QuoteStyle,ExceptionMessages/RedundantExceptionName'
    ]
  end
  Rake::Task[:rubocop].enhance([:rubocop_exception_messages])
end

desc 'Install Appraisal bundles and run each integration in its own environment'
task :integration_specs do
  sh 'bundle', 'exec', 'appraisal', 'install'
  Dir['spec/integration/*'].each do |directory|
    sh 'bundle', 'exec', 'appraisal', File.basename(directory), 'rspec', directory
  end
end

default_tasks = %i[spec]
default_tasks << :integration_specs unless ENV['CI']
default_tasks.unshift(:rubocop) if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.2')
task default: default_tasks
