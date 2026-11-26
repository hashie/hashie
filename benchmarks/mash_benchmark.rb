# frozen_string_literal: true

require_relative 'benchmark_helper'

UPDATE = { 'stargazers_count' => 81, 'topics' => %w[ruby api hashie], 'owner' => { 'site_admin' => true } }.freeze

duel 'Mash.new: a nested JSON response' do
  Hashie::Mash.new(REPOSITORY)
end

duel 'Mash: read keys as methods' do
  once { @mash = Hashie::Mash.new(REPOSITORY) }
  @mash.name
  @mash.owner.login
  @mash.licenses.last.spdx_id
end

duel 'Mash: read keys with suffixes' do
  once { @mash = Hashie::Mash.new(REPOSITORY) }
  @mash.private?
  @mash.owner!.login
  @mash.homepage_
end

duel 'Mash: read keys with [] and dig' do
  once { @mash = Hashie::Mash.new(REPOSITORY) }
  @mash['name']
  @mash[:full_name]
  @mash.dig(:owner, :login)
end

duel 'Mash: write new keys as methods' do |n|
  mashes = untimed { Array.new(n) { Hashie::Mash.new } }
  mashes.each { |mash| mash.name = 'Hello-World' }
end

duel 'Mash: overwrite a key as a method' do
  once { @mash = Hashie::Mash.new(REPOSITORY) }
  @mash.description = 'A first repository'
end

duel 'Mash: respond_to? a key, a suffix and a missing name' do
  once { @mash = Hashie::Mash.new(REPOSITORY) }
  @mash.respond_to?(:name)
  @mash.respond_to?(:archived?)
  @mash.respond_to?(:missing)
end

duel 'Mash#deep_merge: a nested update' do
  once { @mash = Hashie::Mash.new(REPOSITORY) }
  @mash.deep_merge(UPDATE)
end

duel 'Mash#to_hash: a nested Mash' do
  once { @mash = Hashie::Mash.new(REPOSITORY) }
  @mash.to_hash
end
