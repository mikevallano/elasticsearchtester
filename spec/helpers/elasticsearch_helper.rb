RSpec.configure do |config|
  puts "in elasticsearch_helper #{'*' * 100}"
  config.before(:each, elasticsearch: true) do
    Book.create_index!
  end

  config.after(:each, elasticsearch: true) do
    Book.delete_index!
  end
end
