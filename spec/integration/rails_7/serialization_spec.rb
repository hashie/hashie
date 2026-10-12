# frozen_string_literal: true

require 'logger'
require 'active_support'
require 'active_support/cache'
require 'tmpdir'
require 'rspec/core'

RSpec.describe 'Mash FileStore serialization reported in PR #253' do
  it 'preserves the response body and nested Mash classes on a cache hit' do
    require_relative 'app'

    Dir.mktmpdir('hashie-253') do |directory|
      cache = ActiveSupport::Cache::FileStore.new(directory)
      response = { body: Hashie::Mash.new(name: 'mash', child: { name: 'child' }) }

      cache.fetch('response') { response }
      recovered = cache.fetch('response') { raise 'unexpected cache miss' }

      expect(recovered[:body]).to be_an_instance_of(Hashie::Mash)
      expect(recovered[:body].child).to be_an_instance_of(Hashie::Mash)
      expect(recovered[:body].child.name).to eq 'child'
      expect(recovered).to eq response
      expect(recovered[:body]).not_to equal(response[:body])
    end
  end
end
