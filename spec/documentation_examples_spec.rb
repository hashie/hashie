# frozen_string_literal: true

require 'spec_helper'
require 'open3'
require_relative '../script/documentation_examples'

describe DocumentationExamples do
  def run_examples(fixture)
    Open3.capture3(
      RbConfig.ruby, '-Ilib', 'script/test_documentation_examples.rb',
      "spec/fixtures/documentation_examples/#{fixture}.rb"
    )
  end

  it 'executes YARD examples with real assertions and independent namespaces' do
    stdout, stderr, status = run_examples('valid')
    expect(status.exitstatus).to eq(0), "#{stdout}\n#{stderr}"
    expect(stdout).to include('2 examples, 0 failures')
  end

  it 'exits unsuccessfully when an example has an incorrect expected result' do
    stdout, stderr, status = run_examples('invalid')
    expect(status.exitstatus).to eq(1), "#{stdout}\n#{stderr}"
    expect(stdout).to include('1 example, 1 failure', 'expected:', 'wrong', 'abc')
  end

  it 'fails when a public method lacks its own executable example' do
    stdout, stderr, status = run_examples('missing')
    expect(status.exitstatus).not_to eq(0), "#{stdout}\n#{stderr}"
    expect(stderr).to include('public APIs missing executable examples:', 'IncompleteDocumentationExample#undocumented')
  end

  it 'does not require examples for private methods or explicitly internal APIs' do
    stdout, stderr, status = run_examples('private')
    expect(status.exitstatus).to eq(0), "#{stdout}\n#{stderr}"
    expect(stdout).to include('1 example, 0 failures')
  end

  it 'does not silently accept examples without assertions' do
    expect do
      described_class.evaluate('Hashie.stringify_keys(abc: "def")', __FILE__, __LINE__)
    end.to raise_error(ArgumentError, /needs an inline/)
  end

  it 'rejects unsupported standalone result comments' do
    expect do
      described_class.evaluate("1 + 1\n# => 2\n", __FILE__, __LINE__)
    end.to raise_error(ArgumentError, /expected an expression/)
  end

  it 'propagates exceptions from examples' do
    expect do
      described_class.evaluate("raise 'example failed'\n1 # => 1\n", __FILE__, __LINE__)
    end.to raise_error(RuntimeError, 'example failed')
  end

  it 'fails when no examples are selected instead of reporting a false success' do
    expect do
      described_class.run([])
    end.to raise_error(ArgumentError, 'no documentation examples found')
  end
end
