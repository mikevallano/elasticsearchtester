Rails.application.routes.draw do
  devise_for :users
  root 'pages#home'
  get 'pages/about', :about
  resources :books, only: :index
end
