require 'rails_helper'

describe Book, type: :model do

  def search_result(query_hash)
    Book.__elasticsearch__
      .search(query: query_hash)
      .results.results.map{ |res| res.to_h['_source'] }
  end

  describe 'elasticsearch' do
    # let(:critters) { 'cats' }
    # let(:author) { create(:author, first_name: 'Tiglath', last_name: 'Pilesers') }
    # let(:author2) { create(:author, first_name: 'Faith', last_name: 'Hastings') }
    # let(:title) { "#{critters} in space"}
    # let(:title2) { 'Walking in space with a cat named Zorro' }
    # let(:isbn) { rand(10000..20000).to_s }
    # let(:isbn2) { rand(10000..20000).to_s }
    # let(:book) { create(:book, :reindex, title: title, author: author, isbn: isbn) }
    # let(:book2) { create(:book, :reindex, title: title2, author: author2, isbn: isbn2) }

    before(:context) do
      Book.create_index! unless Book.index_exists?
      @critters = 'cats'
      author = create(:author, first_name: 'Tiglath', last_name: 'Pilesers')
      author2 = create(:author, first_name: 'Faith', last_name: 'Hastings')
      title = "#{@critters} in space"
      title2 = 'Walking in space with a cat named Zorro'
      @book = create(:book, :reindex, title: title, author: author)
      @book2 = create(:book, :reindex, title: title2, author: author2)
    end

    after(:context) do
      puts "Book.count: #{Book.count} #{'*' * 100}"
      Book.destroy_all
      Book.delete_index! if Book.index_exists?
    end

    context 'with #term' do
      # Syntax uses the field as the key, followed by an explicit 'value' key
      # Similar to 'SELECT * FROM books WHERE field = query (for keyword field)
      it 'does NOT match on full, exact matched title' do
        query_hash = {
          term: {
            title: {value: @book.title}
          }
        }
        expect(search_result(query_hash).first.try(:[], :id)).to be nil
      end

      it 'DOES match searching one word of the title' do
        query_hash = {
          term: {
            title: {value: @critters}
          }
        }
        expect(search_result(query_hash).first.try(:[], :id)).to eq(@book.id)
      end

      it 'does NOT match singular version of word in the title' do
        query_hash = {
          term: {
            title: {value: @critters.singularize}
          }
        }
        expect(search_result(query_hash).first.try(:[], :id)).not_to eq(@book.id)
      end

      it 'DOES match searching exact match on a keyword field' do
        query_hash = {
          term: {
            isbn: {value: @book.isbn}
          }
        }
        expect(search_result(query_hash).first.try(:[], :id)).to eq(@book.id)
      end

      it 'des NOT match searching partial match of keyword field' do
        query_hash = {
          term: {
            isbn: {value: @book.isbn.first(3)}
          }
        }
        expect(search_result(query_hash).first.try(:[], :id)).not_to eq(@book.id)
      end
    end

    context 'with #terms' do
      # Syntax uses the field as the key, followed by an array of terms
      # Similar to 'SELECT * FROM books WHERE field IN () (for keyword field)
      it 'does NOT match on full, exact matched title' do
        query_hash = {
          terms: { title: [@book.title] }
        }
        expect(search_result(query_hash).first.try(:[], :id)).to be nil
      end

      it 'DOES match searching one word of the title' do
        query_hash = {
          terms: { title: [@critters, 'wrong'] }
        }
        expect(search_result(query_hash).first.try(:[], :id)).to eq(@book.id)
      end

      it 'DOES match when one of the terms matches keyword field' do
        query_hash = {
          terms: { isbn: [@book.isbn, 'wrong'] }
        }
        expect(search_result(query_hash).first.try(:[], :id)).to eq(@book.id)
      end

      it 'does NOT when one of the terms matches only part of a keyword field' do
        query_hash = {
          terms: { isbn: [@book.isbn.first(3), 'wrong'] }
        }
        expect(search_result(query_hash).first.try(:[], :id)).not_to eq(@book.id)
      end
    end

    context 'with #match' do
      # Note syntax with the singular field to be queried followed by the query string
      it 'finds book when searching exact title' do
        query_hash = {
          match: { title: @book.title }
        }
        expect(search_result(query_hash).first.try(:[], :id)).to eq(@book.id)
      end

      it 'finds match when one of the words in the field matches exactly even if another word is not in the field at all' do
        # fbook = create(:book, :reindex, title: ftitle, author: author)
        query_hash = {
          match: { title: 'wrong zorro' }
        }
        expect(search_result(query_hash).first.try(:[], :id)).to eq(@book2.id)
      end

      it 'does NOT match singular version of word in the title' do
        query_hash = {
          match: { title: @critters.singularize }
        }
        expect(search_result(query_hash).first.try(:[], :id)).not_to eq(@book.id)
      end
    end

    context 'with #match_phrase' do
      # Note syntax with the singular field to be queried followed by the query string
      it 'finds book when searching exact title' do
        query_hash = {
          match_phrase: { title: 'cats in' }
        }
        expect(search_result(query_hash).first.try(:[], :id)).to eq(@book.id)
      end

      it 'does NOT match when words are in wrong order' do
        # fbook = create(:book, :reindex, title: title2, author: author)
        query_hash = {
          match_phrase: { title: 'zorro named' }
        }
        expect(search_result(query_hash).first.try(:[], :id)).not_to eq(@book2.id)
      end

      it 'does NOT match when query term is plural but title is singular' do
        # fbook = create(:book, :reindex, title: title2, author: author)
        query_hash = {
          match_phrase: { title: 'cats named' }
        }
        expect(search_result(query_hash).first.try(:[], :id)).not_to eq(@book2.id)
      end

      it 'finds match when words are between using #slop' do
        # NOTE syntax change here where the field is the key, and use of explicit 'query' key
        # fbook = create(:book, :reindex, title: title2, author: author)
        query_hash = {
          match_phrase: {
            title: {query: 'space cat', slop: 2 }
          }
        }
        expect(search_result(query_hash).first.try(:[], :id)).to eq(@book2.id)
      end

      it 'does NOT match singular version of word in the title' do
        query_hash = {
          match_phrase: { title: "#{@critters.singularize} in"}
        }
        expect(search_result(query_hash).first.try(:[], :id)).to be nil
      end
    end

    context 'with #multi_match' do
      it 'finds book when searching exact title' do
        query_hash = {
          multi_match: {
            query: @book.title,
            fields: [:title]
          }
        }
        expect(search_result(query_hash).first.try(:[], :id)).to eq(@book.id)
      end

      it 'finds book when searching query contains a word in the title' do
        query_hash = {
          multi_match: {
            query: @critters,
            fields: [:title]
          }
        }
        expect(search_result(query_hash).first.try(:[], :id)).to eq(@book.id)
      end

      it 'does NOT match on singular version of a word in a text field' do
        query_hash = {
          multi_match: {
            query: @critters.singularize,
            fields: [:title]
          }
        }
        expect(search_result(query_hash).first.try(:[], :id)).not_to eq(@book.id)
      end

      it 'matches when searching author name' do
        query_hash = {
          multi_match: {
            query: @book.author.last_name,
            fields: [:title, :author]
          }
        }
        expect(search_result(query_hash).first.try(:[], :id)).to eq(@book.id)
      end

      it 'does NOT match part of the author name' do
        query_hash = {
          multi_match: {
            query: @book.author.last_name.singularize,
            fields: [:title, :author]
          }
        }
        expect(search_result(query_hash).first.try(:[], :id)).not_to eq(@book.id)
      end
    end

    context 'with #range' do
      # gt: greater than. gte: greater than or equal to
      # lt: less than. lte: less than or equal to
      it 'finds match when query is within range' do
        query_hash = {
          range: {
            id: {
              gte: @book.id
            }
          }
        }
        expect(search_result(query_hash).first.try(:[], :id)).to eq(@book.id)
      end

      it 'does NOT find match when query is outside range' do
        query_hash = {
          range: {
            id: {
              gt: @book.id
            }
          }
        }
        expect(search_result(query_hash).first.try(:[], :id)).not_to eq(@book.id)
      end
    end

    describe 'compound queries' do
      # let(:author2) { create(:author, first_name: 'Faith', last_name: 'Hastings') }
      # let(:isbn2) { rand(10000..20000).to_s }
      # let!(:book2) { create(:book, :reindex, title: title2, author: author2, isbn: isbn2) }

      it 'finds match with #bool' do
        # must and should can also take arrays
        query_hash = {
          bool: {
            must: [{
              term: { title: 'cat' }
            }],
            should: [{
              term: { author: @book2.author.last_name }
            }]
          }
        }
        expect(search_result(query_hash).first.try(:[], :id)).to eq(@book2.id)
      end
    end
  end
end
