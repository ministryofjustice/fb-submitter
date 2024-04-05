Rails.application.routes.draw do
  get '/health', to: 'health#show'
  get '/readiness', to: 'health#readiness'

  namespace 'v2' do
    resources :submissions, only: :create
  end

  resource :metrics, only: [:show]
end
