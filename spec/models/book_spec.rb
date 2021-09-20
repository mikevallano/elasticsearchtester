require 'rails_helper'

describe Book, type: :model do

  def search_result(query_hash)
    Book.__elasticsearch__
      .search(query: query_hash)
      .results.results.map{ |res| res.to_h['_source'] }
  end

  describe 'elasticsearch', :elasticsearch do
    let(:critters) { 'cats' }
    let(:author) { create(:author, first_name: 'Steven', last_name: 'Zimmers') }
    let(:title) { "#{critters} in space"}
    let(:isbn) { rand(1000..2000).to_s }
    let!(:book) { create(:book, :reindex, title: title, author: author, isbn: isbn) }

    context 'with #term' do
      # Syntax uses the field as the key, followed by an explicit 'value' key
      # Similar to 'SELECT * FROM books WHERE field = query (for keyword field)
      it 'does NOT match on full, exact matched title' do
        query_hash = {
          term: {
            title: {value: book.title}
          }
        }
        expect(search_result(query_hash).first.try(:[], :id)).to be nil
      end

      it 'DOES match searching one word of the title' do
        query_hash = {
          term: {
            title: {value: critters}
          }
        }
        expect(search_result(query_hash).first.try(:[], :id)).to eq(book.id)
      end

      it 'does NOT match singular version of word in the title' do
        query_hash = {
          term: {
            title: {value: critters.singularize}
          }
        }
        expect(search_result(query_hash).first.try(:[], :id)).to be nil
      end

      it 'DOES match searching exact match on a keyword field' do
        query_hash = {
          term: {
            isbn: {value: book.isbn}
          }
        }
        expect(search_result(query_hash).first.try(:[], :id)).to eq(book.id)
      end

      it 'des NOT match searching partial match of keyword field' do
        query_hash = {
          term: {
            isbn: {value: book.isbn.first(3)}
          }
        }
        expect(search_result(query_hash).first.try(:[], :id)).to be nil
      end
    end

    context 'with #terms' do
      # Syntax uses the field as the key, followed by an array of terms
      # Similar to 'SELECT * FROM books WHERE field IN () (for keyword field)
      it 'does NOT match on full, exact matched title' do
        query_hash = {
          terms: { title: [book.title] }
        }
        expect(search_result(query_hash).first.try(:[], :id)).to be nil
      end

      it 'DOES match searching one word of the title' do
        query_hash = {
          terms: { title: [critters, 'wrong'] }
        }
        expect(search_result(query_hash).first.try(:[], :id)).to eq(book.id)
      end

      it 'DOES match when one of the terms matches keyword field' do
        query_hash = {
          terms: { isbn: [book.isbn, 'wrong'] }
        }
        expect(search_result(query_hash).first.try(:[], :id)).to eq(book.id)
      end

      it 'does NOT when one of the terms matches only part of a keyword field' do
        query_hash = {
          terms: { isbn: [book.isbn.first(3), 'wrong'] }
        }
        expect(search_result(query_hash).first.try(:[], :id)).to eq(book.id)
      end
    end

    context 'with #match' do
      # Note syntax with the singular field to be queried followed by the query string
      it 'finds book when searching exact title' do
        query_hash = {
          match: { title: book.title }
        }
        expect(search_result(query_hash).first.try(:[], :id)).to eq(book.id)
      end

      it 'does NOT match singular version of word in the title' do
        query_hash = {
          match: { title: critters.singularize }
        }
        expect(search_result(query_hash).first.try(:[], :id)).to be nil
      end
    end

    context 'with #multi_match' do
      it 'finds book when searching exact title' do
        query_hash = {
          multi_match: {
            query: book.title,
            fields: [:title]
          }
        }
        expect(search_result(query_hash).first.try(:[], :id)).to eq(book.id)
      end

      it 'finds book when searching query contains a word in the title' do
        query_hash = {
          multi_match: {
            query: critters,
            fields: [:title]
          }
        }
        expect(search_result(query_hash).first.try(:[], :id)).to eq(book.id)
      end

      it 'does NOT match on singular version of a word in a text field' do
        query_hash = {
          multi_match: {
            query: critters.singularize,
            fields: [:title]
          }
        }
        expect(search_result(query_hash).first.try(:[], :id)).to be nil
      end

      it 'matches when searching author name' do
        query_hash = {
          multi_match: {
            query: author.last_name,
            fields: [:title, :author]
          }
        }
        expect(search_result(query_hash).first.try(:[], :id)).to eq(book.id)
      end

      it 'does NOT match part of the author name' do
        query_hash = {
          multi_match: {
            query: author.last_name.singularize,
            fields: [:title, :author]
          }
        }
        expect(search_result(query_hash).first.try(:[], :id)).to be nil
      end
    end
  end
end
