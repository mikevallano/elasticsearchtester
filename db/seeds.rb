Book.__elasticsearch__.create_index!(force: true)

author1 = Author.create!(first_name: 'John', last_name: 'Back')
author2 = Author.create!(first_name: 'Joe', last_name: 'Doe')

Book.create!(
  title: 'Advanced Ruby on Rails',
  isbn: '1234',
  published_at: (1.year + 2.months).ago,
  author: author1,
  pages: 1000
)
Book.create!(
  title: 'Back To Basics Ruby on Rails',
  isbn: '44356',
  published_at: (3.years - 2.months).ago,
  author: author2,
  pages: 100
)
Book.create!(
  title: 'Ruby: The Best Parts',
  isbn: '2234',
  published_at: 7.months.ago,
  author: author1,
  pages: 569
)
Book.create!(
  title: 'Fun and Profit with Ruby',
  isbn: '4456',
  published_at: (5.years + 5.months).ago,
  author: author1,
  pages: 200
)
Book.create!(
  title: 'JavaScript: The Good Parts',
  isbn: '3234',
  published_at: (2.years - 2.months).ago,
  author: author2, pages: 300
)
Book.create!(
  title: 'JavaScript: The Bad Parts',
  isbn: '88793',
  published_at: (3.years - 2.months).ago,
  author: author2, pages: 1300
)
Book.create!(
  title: 'Build Web Pages with HTML and CSS',
  isbn: '99432',
  published_at: 8.months.ago,
  author: author2,
  pages: 800
)
Book.create!(
  title: 'HTML & CSS for Dummies',
  isbn: '4234',
  published_at: 2.months.ago,
  author: author2,
  pages: 400
)
