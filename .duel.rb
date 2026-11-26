# frozen_string_literal: true

Duel.configure do |c|
  c.benchmarks = 'benchmarks/**/*_benchmark.rb'
  # Two at once on GitHub's 4-CPU runners failed identical code.
  c.jobs = 1
  c.warm = 2
end
