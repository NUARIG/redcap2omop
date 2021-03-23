Rails.application.routes.draw do
  mount Redcap2omop::Engine => "/redcap2omop"
end
