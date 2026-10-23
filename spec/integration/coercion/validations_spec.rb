# frozen_string_literal: true

require 'logger'
require 'active_model'
require 'hashie'

RSpec.describe 'Dash validations with ActiveModel' do
  let(:article_class) do
    stub_const('Article', Class.new(Hashie::Dash) do
      include ActiveModel::Validations

      property :title, required: true

      validates :title, presence: true, length: { maximum: 15 }
    end)
  end

  it 'validates the length boundary only when explicitly requested' do
    expect(article_class.new(title: 'a' * 15)).to be_valid

    article = article_class.new(title: 'a' * 16)
    expect(article.title).to eq('a' * 16)
    expect(article.errors).to be_empty
    expect(article).not_to be_valid
    expect(article.errors[:title]).to eq(['is too long (maximum is 15 characters)'])
    expect(article.errors.full_messages).to eq(['Title is too long (maximum is 15 characters)'])
  end

  it 'retains invalid assignments and clears errors after correcting and revalidating' do
    article = article_class.new(title: 'Hello')
    expect(article).to be_valid

    article.title = 'A title that is too long'
    expect(article.title).to eq('A title that is too long')
    expect(article.errors).to be_empty
    expect(article).not_to be_valid
    expect(article.errors[:title]).not_to be_empty

    article.title = 'Short title'
    expect(article).to be_valid
    expect(article.errors).to be_empty
  end

  it 'distinguishes required properties from ActiveModel presence validation' do
    expect { article_class.new }.to raise_error(ArgumentError, /title.*required/)

    article = article_class.new(title: 'Hello')
    expect { article.title = nil }.to raise_error(ArgumentError, /title.*required/)
    expect(article.title).to eq('Hello')

    article.title = ''
    expect(article.title).to eq('')
    expect(article).not_to be_valid
    expect(article.errors[:title]).to eq(["can't be blank"])
  end

  it 'reports missing optional properties as validation errors instead of raising' do
    optional_class = stub_const('OptionalArticle', Class.new(Hashie::Dash) do
      include ActiveModel::Validations

      property :title

      validates :title, presence: true
    end)

    article = optional_class.new
    expect(article).not_to be_valid
    expect(article.errors[:title]).to include("can't be blank")

    article.title = nil
    expect(article).not_to be_valid
    expect(article.errors[:title]).to include("can't be blank")
  end
end
