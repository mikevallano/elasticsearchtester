class BooksController < ApplicationController
  def index
    fields_to_search = ['title', 'author.first_name', 'author.last_name', 'isbn']
    # fields_to_search = ['title', 'author.first_name', 'isbn']
    # response = Book.__elasticsearch__.search(
    #   query: {
    #     multi_match: {
    #       query: params[:query],
    #       fields: fields_to_search
    #     }
    #   }
    # ).results

    # response = Book.__elasticsearch__.search(
    #   query: {
    #     query_string: {
    #       query: params[:query]
    #     }
    #   }
    # ).results

    # http://localhost:3000/books?query=rails&query_type=term&query_field=title
    query_hash = {
      params[:query_type] => {
        params[:query_field] => params[:query]
      }
    }

    response = Book.__elasticsearch__.search(
      query: query_hash
    ).results

    # response = Book.__elasticsearch__.search(
    #   query: {
    #     term: { # check diff results using 'match'
    #       title: params[:query]
    #     }
    #   }
    # ).results

    # response = Book.__elasticsearch__.search(
    #   query: {
    #     multi_match: {
    #       fields: ['title^3', 'author.last_name'], # the ^ boosts the score by 3
    #       query: params[:query],
    #       type: :phrase,
    #       operator: :and
    #     }
    #   }
    # ).results

    render json: {
      results: response.results.map{ |res| res.to_h['_source'].merge('score' => res['_score']) },
      total: response.total
    }
  end
end
