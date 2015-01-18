Rails.application.routes.draw do
  devise_for :members,
    :controllers => { :omniauth_callbacks => "members/omniauth_callbacks",
                      :invitations => 'members/invitations'
                    }
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  resources :members do
    get :home, on: :member
    post :invite, on: :member
    get :card, on: :member
  end
  resources :memberships

  get 'help', to: 'helps#index'
  post 'verify', to: 'helps#verify'
  get 'confirm', to: 'helps#confirm'
  get 'profile',    to: 'static_pages#profile'

  root :to => 'memberships#index',
    :constraints => RoleConstraint.new("admin"),
    as: :admin_root
  root :to => 'static_pages#profile',
    :constraints => RoleConstraint.new("member"),
    as: :member_root
  root :to => 'static_pages#home',
    as: :unauthenticated_root

  namespace :api, defaults: { format: 'json' } do
    get :ping, to: 'endpoints#ping'

    resources :memberships, only: :create
  end
  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
