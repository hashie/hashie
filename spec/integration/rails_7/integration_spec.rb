ENV['RAILS_ENV'] = 'test'

require 'rspec/core'

RSpec.describe 'rails', type: :request do
  let(:stdout) { StringIO.new }

  around(:each) do |example|
    original_stdout = $stdout
    $stdout = stdout
    require_relative 'app'
    require 'rspec/rails'
    example.run
    $stdout = original_stdout
  end

  it 'does not log anything to STDOUT when initializing' do
    expect(stdout.string).to eq('')
  end

  it 'sets the Hashie logger to the Rails logger' do
    expect(Hashie.logger).to eq(Rails.logger)
  end

  context '#except' do
    subject { Hashie::Mash.new(x: 1, y: 2) }

    it 'returns an instance of the class it was called on' do
      class HashieKlass < Hashie::Mash; end
      hashie_klass = HashieKlass.new(subject)
      expect(hashie_klass.except('x')).to be_a HashieKlass
    end

    it 'works with string keys' do
      expect(subject.except('x')).to eq Hashie::Mash.new(y: 2)
    end

    it 'works with symbol keys' do
      expect(subject.except(:x)).to eq Hashie::Mash.new(y: 2)
    end
  end

  context '#deep_transform_keys' do
    it 'sucessfully deep transforms keys' do
      class HashieDashKlass < Hashie::Dash
        property :foo_bar
        property :foo_baz, required: true
      end
      pending('resolution of https://github.com/hashie/hashie/issues/559')
      dash_klass = HashieDashKlass.new(foo_bar: 'bar', foo_baz: 'baz')
      transformed = dash_klass.deep_transform_keys(&:to_s)
      expect(transformed.keys).to all(be_a(String))
    end
  end

  it 'works' do
    get '/'
    assert_select 'h1', 'Hello, world!'
  end
end
