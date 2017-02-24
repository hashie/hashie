$LOAD_PATH.unshift('lib')

require 'hashie'
require 'benchmark/ips'

mash = Hashie::Mash.new(test: 'value')

Benchmark.ips do |x|
  x.hold!('tmp/mash_benchmark.json')

  x.report('before') { mash.test }
  x.report('after') { mash.test }

  x.compare!
end
