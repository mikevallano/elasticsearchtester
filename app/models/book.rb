require 'elasticsearch/model'

class Book < ApplicationRecord
  belongs_to :author

  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  def as_indexed_json(options = {})
    self.as_json(
      only: [:id, :title, :isbn, :published_at, :pages],
      include: {
        author: {
          only: [:first_name, :last_name]
        }
      }
    )
  end
end
