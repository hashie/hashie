# frozen_string_literal: true

shared_context 'included hash module' do
  subject do
    dummy_class.new
  end

  let!(:dummy_class) do
    klass = Class.new(Hash)
    klass.send :include, described_class
    klass
  end
end
