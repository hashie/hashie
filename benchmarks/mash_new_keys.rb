# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path(File.join('..', 'lib'), __dir__)

require 'hashie'
require 'benchmark/ips'
require 'benchmark/memory'

Hashie.logger = Logger.new(nil)

attributes = {
  'id' => 1, 'name' => 'Hello-World', 'private' => false, 'topics' => %w[ruby hash],
  'owner' => { 'login' => 'mascot', 'id' => 1, 'site_admin' => false }
}

Benchmark.memory do |x|
  x.report('Mash.new') { Hashie::Mash.new(attributes) }
  x.report('mash.key = value') { Hashie::Mash.new.name = 'value' }
end

Benchmark.ips do |x|
  x.report('Mash.new') { Hashie::Mash.new(attributes) }
  x.report('mash.key = value') { Hashie::Mash.new.name = 'value' }
end
