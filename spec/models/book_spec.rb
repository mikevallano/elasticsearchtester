require 'rails_helper'

describe Book, type: :model do

  def search_result(query_hash)
    Book.__elasticsearch__
      .search(query: query_hash)
      .results.results.map{ |res| res.to_h['_source'] }
  end

  def search_result_ids(query_hash)
    search_result(query_hash).map{|r| r.try(:[], :id)}
  end

  describe 'elasticsearch' do
    let(:critters) { 'cats' }
    let(:author) { create(:author, first_name: 'Tiglath', last_name: 'Pilesers') }
    let(:author2) { create(:author, first_name: 'Faith', last_name: 'Hastings') }
    let(:title) { "#{critters} in space"}
    let(:title2) { 'Walking in space with a cat named Zorro' }
    # IDs are hard-coded to ensure the ids are consistent in ES
    let!(:book) { create(:book, :reindex, title: title, author: author, id: 1) }
    let!(:book2) { create(:book, :reindex, title: title2, author: author2, id: 2) }

    before(:context) do
      Book.create_index! unless Book.index_exists?
    end

    after(:context) do
      Book.delete_index! if Book.index_exists?
    end

    context 'with #term' do
      # Syntax uses the field as the key, followed by an explicit 'value' key
      # Similar to 'SELECT * FROM books WHERE field = query (for keyword field)
      it 'does NOT match on full, exact matched title' do
        query_hash = {
          term: {
            title: {value: book.title}
          }
        }
        expect(search_result_ids(query_hash)).to eq([])
      end

      it 'DOES match searching one word of the title' do
        query_hash = {
          term: {
            title: {value: critters}
          }
        }
        expect(search_result_ids(query_hash)).to eq([book.id])
      end

      it 'does NOT match singular version of word in the title' do
        query_hash = {
          term: {
            title: {value: critters.singularize}
          }
        }
        # book2 contains singular 'cat'
        expect(search_result_ids(query_hash)).to eq([book2.id])
      end

      it 'DOES match searching exact match on a keyword field' do
        query_hash = {
          term: {
            isbn: {value: book.isbn}
          }
        }
        expect(search_result_ids(query_hash)).to eq([book.id])
      end

      it 'des NOT match searching partial match of keyword field' do
        query_hash = {
          term: {
            isbn: {value: book.isbn.first(3)}
          }
        }
        expect(search_result_ids(query_hash)).to eq([])
      end
    end

    context 'with #terms' do
      # Syntax uses the field as the key, followed by an array of terms
      # Similar to 'SELECT * FROM books WHERE field IN () (for keyword field)
      it 'does NOT match on full, exact matched title' do
        query_hash = {
          terms: { title: [book.title] }
        }
        expect(search_result_ids(query_hash)).to eq([])
      end

      it 'DOES match searching one word of the title' do
        query_hash = {
          terms: { title: [critters, 'wrong'] }
        }
        expect(search_result_ids(query_hash)).to eq([book.id])
      end

      it 'DOES match when one of the terms matches keyword field' do
        query_hash = {
          terms: { isbn: [book.isbn, 'wrong'] }
        }
        expect(search_result_ids(query_hash)).to eq([book.id])
      end

      it 'does NOT when one of the terms matches only part of a keyword field' do
        query_hash = {
          terms: { isbn: [book.isbn.first(3), 'wrong'] }
        }
        expect(search_result_ids(query_hash)).to eq([])
      end
    end

    context 'with #match' do
      # Note syntax with the singular field to be queried followed by the query string
      it 'finds book when searching exact title' do
        query_hash = {
          match: { title: book.title }
        }
        # Matches book2 because of similarity?
        expect(search_result_ids(query_hash)).to eq([book.id, book2.id])
      end

      it 'finds match when one of the words in the field matches exactly even if another word is not in the field at all' do
        query_hash = {
          match: { title: 'wrong zorro' }
        }
        expect(search_result_ids(query_hash)).to eq([book2.id])
      end

      it 'does NOT match singular version of word in the title' do
        query_hash = {
          match: { title: critters.singularize }
        }
        # Does not match book1 because of singular 'cat'
        expect(search_result_ids(query_hash)).to eq([book2.id])
      end
    end

    context 'with #match_phrase' do
      # Note syntax with the singular field to be queried followed by the query string
      it 'finds book when searching exact phrase match' do
        query_hash = {
          match_phrase: { title: 'cats in' }
        }
        expect(search_result_ids(query_hash)).to eq([book.id])
      end

      it 'does NOT match when words are in wrong order' do
        query_hash = {
          match_phrase: { title: 'zorro named' }
        }
        expect(search_result_ids(query_hash)).to eq([])
      end

      it 'does NOT match when query term is plural but title is singular' do
        query_hash = {
          match_phrase: { title: 'cats named' }
        }
        expect(search_result_ids(query_hash)).to eq([])
      end

      it 'finds match when words are between using #slop' do
        # NOTE syntax change here where the field is the key, and use of explicit 'query' key
        query_hash = {
          match_phrase: {
            title: {query: 'space cat', slop: 2 }
          }
        }
        # Does not match book2 because 'space' ?
        expect(search_result_ids(query_hash)).to eq([book2.id])
      end

      it 'does NOT match singular version of word in the title' do
        query_hash = {
          match_phrase: { title: "#{critters.singularize} in"}
        }
        expect(search_result_ids(query_hash)).to eq([])
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
        # Still matches book2 since there are enough common words?
        expect(search_result_ids(query_hash)).to eq([book.id, book2.id])
      end

      it 'finds book when searching query contains a word in the title' do
        query_hash = {
          multi_match: {
            query: critters,
            fields: [:title]
          }
        }
        # book2 contains a singular version of the query
        expect(search_result_ids(query_hash)).to eq([book.id])
      end

      it 'does NOT match on singular version of a word in a text field' do
        query_hash = {
          multi_match: {
            query: critters.singularize,
            fields: [:title]
          }
        }
        # book2 has the exact match 'cat' in the title
        expect(search_result_ids(query_hash)).to eq([book2.id])
      end

      it 'matches when searching author name' do
        query_hash = {
          multi_match: {
            query: book.author.last_name,
            fields: [:title, :author]
          }
        }
        expect(search_result_ids(query_hash)).to eq([book.id])
      end

      it 'does NOT match part of the author name' do
        query_hash = {
          multi_match: {
            query: book.author.last_name.singularize,
            fields: [:title, :author]
          }
        }
        expect(search_result_ids(query_hash)).to eq([])
      end
    end

    context 'with #range' do
      # gt: greater than. gte: greater than or equal to
      # lt: less than. lte: less than or equal to
      it 'finds match when query is within range' do
        query_hash = {
          range: {
            id: {
              gte: book.id
            }
          }
        }
        # TODO: not sure if range does scoring
        expect(search_result_ids(query_hash)).to match_array([book.id, book2.id])
      end

      it 'does NOT find match when query is outside range' do
        query_hash = {
          range: {
            id: {
              gt: book.id
            }
          }
        }
        expect(search_result_ids(query_hash)).to eq([book2.id])
      end
    end

    describe 'compound queries' do
      it 'finds match with #bool' do
        # must and should can also take arrays
        query_hash = {
          bool: {
            must: [{
              term: { title: 'cat' }
            }],
            should: [{
              term: { author: book2.author.last_name }
            }]
          }
        }
        expect(search_result_ids(query_hash)).to eq([book2.id])
      end
    end
  end
end
