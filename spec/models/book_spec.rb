require 'rails_helper'

describe Book, type: :model do

  def search_result(query_hash)
    Book.__elasticsearch__
      .search(query: query_hash)
      .results.results.map{ |res| res.to_h['_source'] }
  end

  it 'has a valid factory' do
    book = build(:book)
    expect(book).to be_valid
  end

  describe 'elasticsearch', :elasticsearch do
    let(:critters) { 'cats' }
    let(:title) { "#{critters} in space"}
    let!(:book) { create(:book, :reindex, title: title) }
    context 'with multi_match' do
      it 'finds book when searching exact title' do
        query_hash = {
          multi_match: {
            query: title,
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
    end
  end
end
