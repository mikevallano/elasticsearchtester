FactoryBot.define do
  factory :book do
    title { "MyString" }
    isbn { rand(10000..20000).to_s }
    published_at { "2021-09-16" }
    pages { 1 }
    association :author

    trait :reindex do
      after(:create) { Book.refresh_index! }
    end
  end
end
