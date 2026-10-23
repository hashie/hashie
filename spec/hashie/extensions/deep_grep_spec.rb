# frozen_string_literal: true

require 'spec_helper'

describe Hashie::Extensions::DeepGrep do
  let(:books) do
    {
      'Uncategorized' => [
        { title: 'Ruby for beginners', pages: 120 },
        { title: 'CSS for intermediates', pages: 80 }
      ],
      'Collection of Elixir books' => [{ title: 'Programming Elixir', pages: 689 }],
      'Collection of Ruby books' => [{ title: 'That other language by Matz', pages: 578 }]
    }
  end

  it 'returns matching books and key subtrees rather than the entire library' do
    expected = [
      books['Uncategorized'].first,
      { 'Collection of Ruby books' => books['Collection of Ruby books'] }
    ]
    expect(described_class.deep_grep(/ruby/i, books)).to eq(expected)
  end

  it 'supports extended objects and included subclasses without changing Enumerable#grep' do
    books.extend(described_class)
    klass = Class.new(Hash) { include Hashie::Extensions::DeepGrep }
    expect(klass[books].deep_grep(/ruby/i)).to eq(books.deep_grep(/ruby/i))
    expect(books.grep(Array)).to eq(books.to_a)
  end

  it 'returns only matching string and symbol elements from nested arrays in depth-first order' do
    data = [{ title: 'Ruby' }, ['CSS', [:ruby, 42, nil, false, 'Ruby again']], { name: 'Rubyist' }]
    expected = [data.first, :ruby, 'Ruby again', data.last]
    expect(described_class.deep_grep(/ruby/i, data)).to eq(expected)
  end

  it 'returns a containing hash once when multiple scalar values match' do
    data = { title: 'Ruby', language: :ruby, pages: 120 }
    result = described_class.deep_grep(/ruby/i, data)
    expect(result).to eq([data])
    expect(result.first).to equal(data)
  end

  it 'matches symbol keys and stops descending into matching key subtrees' do
    subtree = [{ ruby: 'Ruby' }]
    data = { ruby_books: subtree, other: { title: 'Ruby' } }
    result = described_class.deep_grep(/ruby/i, data)
    expect(result).to eq([{ ruby_books: subtree }, data[:other]])
    expect(result.first[:ruby_books]).to equal(subtree)
    expect(data).to eq(ruby_books: subtree, other: { title: 'Ruby' })
  end

  it 'does not stringify non-text values or search inside container keys' do
    data = { 123 => 456, ['Ruby'] => true, nil => false }
    expect(described_class.deep_grep(/Ruby|123|456|true|false/, data)).to eq([])
    expect(described_class.deep_grep(/anything/, {})).to eq([])
    expect(described_class.deep_grep(/anything/, [])).to eq([])
  end

  it 'handles cycles while preserving repeated occurrences of shared containers' do
    shared = { title: 'Ruby' }
    data = [shared, shared]
    data << data
    shared[:parent] = data
    expect(described_class.deep_grep(/Ruby/, data)).to eq([shared, shared])
  end

  it 'rejects non-regexp patterns explicitly' do
    expect { described_class.deep_grep('Ruby', books) }
      .to raise_error(ArgumentError, 'pattern must be a Regexp')
  end
end
