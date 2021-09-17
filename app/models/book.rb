require 'elasticsearch/model'

class Book < ApplicationRecord
  belongs_to :author

  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  def self.all_elastic_results
    self.__elasticsearch__.search('*:*')
  end

  def self.index_exists?
    self.__elasticsearch__.index_exists?
  end

  def self.create_index!
    self.__elasticsearch__.create_index!
  end

  def self.delete_index!
    return unless self.index_exists?
    self.__elasticsearch__.delete_index!
  end

  def self.refresh_index!
    return unless self.index_exists?
    self.__elasticsearch__.refresh_index!
  end

  settings index: { number_of_shards: 1 }
  mappings(dynamic: 'false') do
    indexes :id, type: :keyword
    indexes :title, type: :text
    indexes :isbn, type: :keyword
    indexes :published_at, type: :date
    indexes :author, type: :text
  end

  def as_indexed_json(options = {})
    # self.as_json(
    #   only: [:id, :title, :isbn, :published_at, :pages],
    #   include: {
    #     author: {
    #       only: [:first_name, :last_name]
    #     }
    #   }
    # )
    {
      id: id,
      title: title,
      isbn: isbn,
      published_at: published_at,
      pages: pages,
      author: "#{author.first_name} #{author.last_name}"
    }
  end
end
