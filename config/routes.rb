Rails.application.routes.draw do
  resources :orders do |order|
    resource :checkout, :controller => "checkout" do
      member do 
        get :paypal_checkout
        get :paypal_payment
        match "paypal_confirm"
        get :paypal_finish
      end
    end
  end

  match "/ipn" => "paypal_standard_callbacks#notify", :as => :notify, :via => [ :get, :post ]

  resources :paypal_standard_callbacks
  namespace :admin do
    resources :orders do
      resources :paypal_payments do
        member do
          get :refund
          get :capture
        end       
      end
    end
  end
end
