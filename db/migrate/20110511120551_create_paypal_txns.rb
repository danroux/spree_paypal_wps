class CreatePaypalTxns < ActiveRecord::Migration
  def self.up
      create_table :paypal_txns do |t|
      t.references :paypal_account
      t.decimal :gross_amount, :precision => 8, :scale => 2
      t.string :payment_status
      t.text :message
      t.string :pending_reason
      t.string :txn_type
      t.string :txn_id
      t.string :payment_type
      t.string :ack
      t.string :token
      t.string :avs_code
      t.string :cvv_code
      t.timestamps
    end
  end

  def self.down
    drop_table :paypal_txns
  end
end
