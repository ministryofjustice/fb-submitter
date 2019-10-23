Rails.application.routes.draw do
  get '/health', to: 'health#show'
  get '/submission/:id', to: 'submission#show'
  post '/submission', to: 'submission#create'

  post '/email', to: 'email#create'
  post '/sms', to: 'sms#create'

  resource :metrics, only: [:show]
end
