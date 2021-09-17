FactoryBot.define do
  factory :book do
    name { "MyString" }
    isbn { "MyString" }
    author { nil }
    published_at { "2021-09-16" }
    pages { 1 }
  end
end
