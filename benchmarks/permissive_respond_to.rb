#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path(File.join('..', 'lib'), __dir__)

require 'hashie'
require 'benchmark/ips'
require 'benchmark/memory'

permissive = Class.new(Hashie::Mash)

Benchmark.memory do |x|
  x.report('Default') {}
  x.report('Make permissive') do
    permissive.include Hashie::Extensions::Mash::PermissiveRespondTo
  end
end

class PermissiveMash < Hashie::Mash
  include Hashie::Extensions::Mash::PermissiveRespondTo
end

Benchmark.ips do |x|
  x.report('Mash.new') { Hashie::Mash.new(a: 1) }
  x.report('Permissive.new') { PermissiveMash.new(a: 1) }

  x.compare!
end

Benchmark.ips do |x|
  x.report('Mash#attr=') { Hashie::Mash.new.a = 1 }
  x.report('Permissive#attr=') { PermissiveMash.new.a = 1 }

  x.compare!
end

mash = Hashie::Mash.new(a: 1)
permissive = PermissiveMash.new(a: 1)

Benchmark.ips do |x|
  x.report('Mash#attr= x2') { mash.a = 1 }
  x.report('Permissive#attr= x2') { permissive.a = 1 }

  x.compare!
end
