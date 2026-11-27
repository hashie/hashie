# frozen_string_literal: true

Duel.configure do |c|
  c.benchmarks = 'benchmarks/**/*_benchmark.rb'
  # Two at once on GitHub's 4-CPU runners failed identical code.
  c.jobs = 1
  # Identical-code comparisons exceeded Duel's default CPU margin.
  c.measure('cpu', limit: 1.05)
  # With 12 workers, the fastest benchmarks' timings were often too close to call.
  c.processes = 24
  c.warm = 2
end
