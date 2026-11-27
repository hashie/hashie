# frozen_string_literal: true

require_relative 'benchmark_helper'

class KeepingMash < Hashie::Mash
  include Hashie::Extensions::Mash::KeepOriginalKeys
end

class PermissiveMash < Hashie::Mash
  include Hashie::Extensions::Mash::PermissiveRespondTo
end

class IndifferentHash < Hash
  include Hashie::Extensions::MergeInitializer
  include Hashie::Extensions::IndifferentAccess
end

class DeepHash < Hash
  include Hashie::Extensions::MergeInitializer
  include Hashie::Extensions::DeepFetch
  include Hashie::Extensions::DeepFind
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
  once { @mash = KeepingMash.new(repository.slice(*KEYS.map(&:to_s))) }
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

duel 'IndifferentAccess: new from a nested JSON response' do |n|
  attributes = untimed { Array.new(n) { repository } }
  attributes.each { |hash| IndifferentHash.new(hash) }
end

duel 'IndifferentAccess: read String and Symbol keys' do
  once { @hash = IndifferentHash.new(repository) }
  @hash['name']
  @hash[:full_name]
  @hash[:owner]['login']
  @hash.fetch(:homepage)
  @hash.key?(:archived)
end

duel 'IndifferentAccess: write String and Symbol keys' do
  once { @hash = IndifferentHash.new(repository) }
  @hash[:description] = 'A first repository'
  @hash['homepage'] = 'https://example.com'
  @hash.store(:stargazers_count, 81)
end

duel 'DeepFind and DeepFetch: nested keys' do
  once { @hash = DeepHash.new(repository) }
  @hash.deep_find('login')
  @hash.deep_find_all('spdx_id')
  @hash.deep_fetch('owner', 'login')
  @hash.deep_fetch('licenses', 1, 'spdx_id')
end
