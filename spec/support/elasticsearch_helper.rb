RSpec.configure do |config|
  config.before(:each, elasticsearch: true) do
    Book.create_index! unless Book.index_exists?
  end

  config.after(:each, elasticsearch: true) do
    Book.delete_index!
  end
end
