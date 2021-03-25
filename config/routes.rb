Redcap2omop::Engine.routes.draw do
  get '/redcap_projects', to: 'redcap_projects#index'
  resources  :redcap_variable_maps
end
