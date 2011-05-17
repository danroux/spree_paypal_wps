class PaypalTxn < ActiveRecord::Base
  belongs_to :paypal_account
  enumerable_constant :txn_type, :constants => [:authorize, :capture, :purchase, :void, :credit, :denied, :unknown]
end
