require 'rails_helper'
# require '/spec/helpers/elasticsearch_helper.rb'

describe Book, type: :model do
  it 'has a valid factory' do
    book = build(:book)
    expect(book).to be_valid
  end

  describe 'elasticsearch', :elasticsearch do
    after { Book.delete_index! }
    it 'searches elasticsearch successfully' do
      title = 'cats in space'
      book = create(:book, title: title)
      Book.refresh_index!
      response = Book.__elasticsearch__.search(
        query: {
          multi_match: {
            query: title,
            fields: [:title]
          }
        }
      ).results.results.map{ |res| res.to_h['_source'] }
      expect(response.first[:id]).to eq(book.id)
    end

    context 'with multi_match' do
      it 'finds book when searching exact title' do
        title = 'cats in space'
        book = create(:book, title: title)
        Book.refresh_index!
        response = Book.__elasticsearch__.search(
          query: {
            multi_match: {
              query: title,
              fields: [:title]
            }
          }
        ).results.results.map{ |res| res.to_h['_source'] }
        expect(response.first[:id]).to eq(book.id)
      end

      it 'finds book when searching partial title' do
        title = 'cats in space'
        book = create(:book, title: title)
        Book.refresh_index!
        response = Book.__elasticsearch__.search(
          query: {
            multi_match: {
              query: 'cat',
              fields: [:title],
              fuzziness: 1
            }
          }
        ).results.results.map{ |res| res.to_h['_source'] }
        expect(response.first.try(:[], :id)).to eq(book.id)
      end
    end
  end
end
