# frozen_string_literal: true

require 'hashie/yard'
require 'open3'

RSpec.describe 'opt-in Dash YARD handler' do
  let(:fixture) { File.join(__dir__, 'fixtures', 'dash.rb') }

  before do
    YARD::Registry.clear
    YARD.parse(fixture)
  end

  after { YARD::Registry.clear }

  def attribute(name)
    YARD::Registry.at('YardExamples::Person').attributes[:instance].fetch(name.to_sym)
  end

  it 'generates separate reader and writer attributes with the declaration documentation' do
    reader, writer = attribute('name').values_at(:read, :write)
    expect(reader.path).to eq('YardExamples::Person#name')
    expect(writer.path).to eq('YardExamples::Person#name=')
    expect(reader.parameters).to eq([])
    expect(writer.parameters).to eq([['value', nil]])
    [reader, writer].each do |object|
      expect(object.docstring.to_s).to include("The person's name.")
      expect(object.tag(:return).types).to eq(['String'])
      expect(object.file).to eq(fixture)
      expect(object.line).to eq(7)
      expect(object.tags(:note).map(&:text)).to include('Required.')
    end
  end

  it 'provides fallback documentation and retains literal defaults and required flags as source' do
    reader = attribute('age')[:read]
    writer = attribute('age')[:write]
    expect(reader.docstring.to_s).to include('Returns the value of age.')
    expect(writer.tag(:param).name).to eq('value')
    expect(reader['hashie_default']).to eq('3')
    expect(reader['hashie_required']).to eq('false')
    expect(reader.tags(:note).map(&:text)).to eq([
      'Default (Ruby source): `3`.', 'Not required.'
    ])
    expect(attribute('enabled')[:read]['hashie_default']).to eq('false')
    expect(attribute('enabled')[:read]['hashie_required']).to eq('nil')
    expect(attribute('nickname')[:read]['hashie_default']).to eq("'anonymous'")
  end

  it 'documents dynamic expressions without evaluating source or claiming a boolean result' do
    reader = attribute('token')[:read]
    expect(reader['hashie_default']).to eq("-> { raise 'must not execute defaults' }")
    expect(reader.tags(:note).map(&:text)).to include(
      'Required condition (Ruby source): `:needs_token?`.'
    )
    expect(attribute('unsafe')[:read]['hashie_default']).to eq(
      "raise('must not evaluate source')"
    )
    expect(attribute('unknown')[:read]['hashie_default']).to be_nil
    expect(attribute('dynamic_key')[:read]['hashie_default']).to be_nil
    expect(attribute('dynamic_options')[:read]['hashie_default']).to be_nil
  end

  it 'discovers indirect descendants using the YARD registry' do
    expect(YARD::Registry.at('YardExamples::Child#child')).not_to be_nil
    expect(YARD::Registry.at('YardExamples::Grandchild#grandchild=')).not_to be_nil
  end

  it 'renders property documentation and metadata with the standard HTML templates' do
    options = YARD::CLI::Yardoc.new.options
    html = YARD::Templates::Engine.render(
      options.merge(object: attribute('age')[:read], type: :method, format: :html, serialize: false)
    )
    expect(html).to include('Returns the value of age.')
    expect(html).to match(/Default \(Ruby source\):.*3/)
    expect(html).to include('Not required.')
  end

  it 'ignores unrelated DSLs, nondeclarations and dynamic property names' do
    %w[Other#not_a_dash Unresolved#not_discoverable Cycle#not_a_dash NotAClass#not_a_class].each do |path|
      expect(YARD::Registry.at("YardExamples::#{path}")).to be_nil
    end
    names = YARD::Registry.at('YardExamples::Person').attributes[:instance].keys.map(&:to_s)
    expect(names).to match_array(
      %w[name age enabled nickname token unsafe unknown dynamic_key dynamic_options]
    )
  end

  it 'does not load YARD or Dash during normal Hashie loading' do
    source = <<~RUBY
      require 'hashie'
      abort 'loaded YARD' if defined?(YARD)
      abort 'loaded Dash' if $LOADED_FEATURES.any? { |file| file.end_with?('/hashie/dash.rb') }
      abort 'changed autoload' unless Hashie.autoload?(:Dash) == 'hashie/dash'
      Hashie::Dash.new
      abort 'loaded YARD through Dash' if defined?(YARD)
    RUBY
    output, status = Open3.capture2e(Gem.ruby, '-e', source)
    expect(status.success?).to be(true), output
  end

  it 'loads explicitly through the YARD CLI without loading the Dash runtime' do
    source = <<~RUBY
      require 'yard'
      YARD::CLI::Yardoc.run('--no-save', '--no-output', '-e', 'hashie/yard.rb', ARGV.fetch(0))
      abort 'missing attribute' unless YARD::Registry.at('YardExamples::Person#name=')
      abort 'loaded Dash' if $LOADED_FEATURES.any? { |file| file.end_with?('/hashie/dash.rb') }
    RUBY
    output, status = Open3.capture2e(Gem.ruby, '-e', source, fixture)
    expect(status.success?).to be(true), output
  end
end
