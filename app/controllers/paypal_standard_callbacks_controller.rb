class PaypalStandardCallbacksController < Spree::BaseController
  include ActiveMerchant::Billing::Integrations
  skip_before_filter :verify_authenticity_token

  def notify
    retrieve_details

    @notification = Paypal::Notification.new(request.raw_post)
    # @notification.params["payment_type"] == "echeck"

    if @notification.complete? &&  @payment && @payment.amount >= @order.total
      case @notification.params["payment_status"]
        when "Denied"
          create_txn PaypalTxn::TxnType::DENIED

        when "Completed"
          create_txn PaypalTxn::TxnType::CAPTURE
      end
    end

    render(:nothing => true)
  end

  private
    def retrieve_details
      @order = Order.find_by_number(params["custom"])

      if @order
        @paypal_account = PaypalAccount.find_or_initialize_by_email(params["payer_email"])
        if @paypal_account.new_record?
          @paypal_account.update_attributes(:payer_id => params["payer_id"], :payer_status => params["payer_status"])
        end
        payment_method = PaymentMethod.find_by_type("PaymentMethod::PaypalStandard")
        @payment = @paypal_account.payments.new(:amount => params["mc_gross"],
                                                :source => @paypal_account,
                                                :payment_method => payment_method)
      end
    end

    def create_txn(txn_type)
      if txn_type == PaypalTxn::TxnType::CAPTURE
        @order.payments << @payment
        @paypal_account.paypal_txn = PaypalTxn.new(:gross_amount   => @notification.params["mc_gross"].to_f,
                                                   :payment_status => @notification.params["payment_status"],
                                                   :txn_id         => @notification.params["txn_id"],
                                                   :txn_type       => @notification.params["txn_type"],
                                                   :payment_type   => @notification.params["payment_type"])
        @payment.process!
      elsif txn_type == PaypalTxn::TxnType::DENIED
        #maybe we should do something?
      end

    end
end
