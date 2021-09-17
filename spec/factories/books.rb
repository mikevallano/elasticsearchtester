FactoryBot.define do
  factory :book do
    title { "MyString" }
    isbn { "MyString" }
    published_at { "2021-09-16" }
    pages { 1 }
    association :author
  end
end
