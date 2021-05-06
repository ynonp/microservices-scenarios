Rails.application.routes.draw do
  post "/graphql", to: "graphql#execute"
  root to: 'meetings#index'
  resources :meetings
  resources :contact_infos
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
