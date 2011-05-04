class PaypalStandardCallbacksController < Spree::BaseController

  include ActiveMerchant::Billing::Integrations

  skip_before_filter :verify_authenticity_token

  def notify
    ActiveMerchant::Billing::Base.integration_mode = :production

    @order = Order.find_by_number(params["custom"])
    @notification = Paypal::Notification.new(request.raw_post)

    if(@notification.acknowledge && @notification.complete?)
      # TODO: Finish the order.
    end

    render(:nothing => true)

  end

end
