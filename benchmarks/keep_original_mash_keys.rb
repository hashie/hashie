require_relative '../lib/hashie'
require 'benchmark/ips'

class KeepingMash < Hashie::Mash
  include Hashie::Extensions::Mash::KeepOriginalKeys
end

original = { test: 'value' }
mash = Hashie::Mash.new(original)
keeping_mash = KeepingMash.new(original)

Benchmark.ips do |x|
  x.report('keep symbol') { keeping_mash.test }
  x.report('normal symbol') { mash.test }

  x.compare!
end

original = { 'test' => 'value' }
mash = Hashie::Mash.new(original)
keeping_mash = KeepingMash.new(original)

Benchmark.ips do |x|
  x.report('keep string') { keeping_mash.test }
  x.report('normal string') { mash.test }

  x.compare!
end
