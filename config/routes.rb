Rails.application.routes.draw do
  # TODO: translate these routes to rails 3 format.
  #map.resources :orders do |order|
  #  order.resource :checkout, :member => { :paypal_payment => :any, :paypal_confirm => :any }
  #end

  #map.paypal_notify "/paypal_notify", :controller => :paypal_standard_callbacks, :action => :notify, :method => [:post, :get]

  #map.namespace :admin do |admin|
  #  admin.resources :orders do |order|
  #    order.resources :paypal_payments, :member => {:capture => :get, :refund => :any}, :has_many => [:txns]
  #  end
  #end

  resources :orders do |order|
    resource :checkout, :controller => "checkout" do
      match :paypal_payment, :on => :member
      match :paypal_confirm, :on => :member
    end
  end
end
