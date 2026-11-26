# frozen_string_literal: true

require_relative 'benchmark_helper'

class KeepingMash < Hashie::Mash
  include Hashie::Extensions::Mash::KeepOriginalKeys
end

class PermissiveMash < Hashie::Mash
  include Hashie::Extensions::Mash::PermissiveRespondTo
end

KEYS = %i[id name full_name description homepage].freeze

duel 'Mash: read keys given as Symbols as methods' do
  once { @mash = Hashie::Mash.new(repository_attributes(*KEYS)) }
  @mash.id
  @mash.name
  @mash.full_name
  @mash.description
  @mash.homepage
end

duel 'KeepOriginalKeys: read Symbol keys as methods' do
  once { @mash = KeepingMash.new(repository_attributes(*KEYS)) }
  @mash.id
  @mash.name
  @mash.full_name
  @mash.description
  @mash.homepage
end

duel 'KeepOriginalKeys: read String keys as methods' do
  once { @mash = KeepingMash.new(REPOSITORY.slice(*KEYS.map(&:to_s))) }
  @mash.id
  @mash.name
  @mash.full_name
  @mash.description
  @mash.homepage
end

duel 'PermissiveRespondTo: include in a Mash subclass' do |n|
  classes = untimed { Array.new(n) { Class.new(Hashie::Mash) } }
  classes.each { |klass| klass.include(Hashie::Extensions::Mash::PermissiveRespondTo) }
end

duel 'Mash.new: a flat Hash' do
  Hashie::Mash.new(a: 1)
end

duel 'PermissiveRespondTo: Mash.new' do
  PermissiveMash.new(a: 1)
end

duel 'PermissiveRespondTo: write a new key as a method' do |n|
  mashes = untimed { Array.new(n) { PermissiveMash.new } }
  mashes.each { |mash| mash.a = 1 }
end

duel 'PermissiveRespondTo: overwrite a key as a method' do
  once { @mash = PermissiveMash.new(a: 1) }
  @mash.a = 1
end
