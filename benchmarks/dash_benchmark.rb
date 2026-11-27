# frozen_string_literal: true

require_relative 'benchmark_helper'

class RepositoryDash < Hashie::Dash
  property :id, required: true
  property :name, required: true
  property :full_name
  property :description
  property :stargazers_count, default: 0
  property :topics, default: []
  property :archived, default: false
end

class RepositoryTrash < Hashie::Trash
  property :id
  property :title, from: :full_name
  property :stars, from: :stargazers_count
  property :topics, transform_with: ->(topics) { topics.join(', ') }
end

class CoercedRepositoryDash < Hashie::Dash
  include Hashie::Extensions::Dash::Coercion

  property :id, coerce: Integer
  property :name, coerce: String
  property :stargazers_count, coerce: Integer
  property :topics, coerce: [String]
end

class IndifferentRepositoryDash < Hashie::Dash
  include Hashie::Extensions::Dash::IndifferentAccess

  property :id
  property :name
  property :full_name
  property :description
end

class OwnerDash < Hashie::Dash
  include Hashie::Extensions::IgnoreUndeclared

  property :login
  property :id
  property :site_admin
end

class LicenseDash < Hashie::Dash
  include Hashie::Extensions::IgnoreUndeclared

  property :key
  property :spdx_id
end

class NestedRepositoryDash < Hashie::Dash
  include Hashie::Extensions::Dash::Coercion

  property :id
  property :owner, coerce: OwnerDash
  property :licenses, coerce: [LicenseDash]
end

duel 'Dash.new: required properties and defaults' do
  once { @attributes = repository_attributes(:id, :name, :full_name, :description) }
  RepositoryDash.new(@attributes)
end

duel 'Dash: read and write properties' do
  once { @dash = RepositoryDash.new(repository_attributes(:id, :name, :full_name, :description, :stargazers_count)) }
  @dash.name
  @dash.full_name
  @dash[:stargazers_count]
  @dash[:topics]
  @dash.description = 'A first repository'
  @dash[:archived] = true
end

duel 'Trash.new: renamed and transformed properties' do
  once { @attributes = repository_attributes(:id, :full_name, :stargazers_count, :topics) }
  RepositoryTrash.new(@attributes)
end

duel 'Dash.new: coerced properties' do
  once { @attributes = { id: '1296269', name: :'Hello-World', stargazers_count: '80', topics: %i[octocat api] }.freeze }
  CoercedRepositoryDash.new(@attributes)
end

duel 'Dash.new: String keys with IndifferentAccess' do
  once { @attributes = repository.slice('id', 'name', 'full_name', 'description').freeze }
  IndifferentRepositoryDash.new(@attributes)
end

duel 'Dash.new: coerced nested Dashes' do
  once { @attributes = JSON.parse(REPOSITORY_JSON, symbolize_names: true).slice(:id, :owner, :licenses).freeze }
  NestedRepositoryDash.new(@attributes)
end
