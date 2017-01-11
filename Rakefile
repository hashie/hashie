require 'rubygems'
require 'bundler'
Bundler.setup

Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
end

require 'rubocop/rake_task'
RuboCop::RakeTask.new(:rubocop)

require 'ruby_engine'
if RubyEngine.is? 'rbx'
  # Rubinius 2.5.8 crashes Rubocop:
  # https://github.com/rubinius/rubinius/issues/3485
  task default: [:spec]
else
  task default: [:rubocop, :spec]
end
