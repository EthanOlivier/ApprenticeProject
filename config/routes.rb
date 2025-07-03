Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  get "main", to: "home#main"
  root "home#root"
end
