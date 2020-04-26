Rails.application.routes.draw do
  mount Crudify::Engine => "/crudify"
end
