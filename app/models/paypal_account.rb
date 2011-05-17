class PaypalAccount < ActiveRecord::Base
  has_many :payments, :as => :source
  has_one  :paypal_txn

  def process!(payment)
    payment.complete
  end
end
