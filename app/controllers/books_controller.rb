class BooksController < ApplicationController
  def index
    fields_to_search = ['title', 'author.first_name', 'author.last_name', 'isbn']
    # fields_to_search = ['title', 'author.first_name', 'isbn']
    response = Book.__elasticsearch__.search(
      query: {
        multi_match: {
          query: params[:query],
          fields: fields_to_search
        }
      }
    ).results

    # response = Book.__elasticsearch__.search(
    #   query: {
    #     query_string: {
    #       query: params[:query]
    #     }
    #   }
    # ).results

    # response = Book.__elasticsearch__.search(
    #   query: {
    #     term: {
    #       title: params[:query]
    #     }
    #   }
    # ).results

    render json: {
      results: response.results,
      total: response.total
    }
  end
end
