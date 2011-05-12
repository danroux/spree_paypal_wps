module Spree::PaypalStandard
  include ERB::Util

  def self.included(target)
    target.before_filter :redirect_to_paypal_standard_form_if_needed, :only => [:update]
  end

  # Outbound redirect to PayPal from checkout payments step
  def paypal_payment
    load_order
    opts = all_opts(@order, params[:payment_method_id], 'checkout')

    url_params = "?"
    url_params += "business=#{payment_method.preferences["account"]}"
    url_params += "&cmd=_cart"
    url_params += "&currency_code=MXN"
    url_params += "&charset=utf-8"
    url_params += "&return=" + CGI::escape(opts[:return_url])
    url_params += "&no_shipping=1&no_note=1&lc=MX&upload=1"
    url_params += "&custom=#{opts[:custom]}"
    counter = 1
    opts[:items].each do |item|
      item_name = item[:name]
      url_params += "&item_name_#{counter}=#{item_name}"
      url_params += "&item_number_#{counter}=#{item[:sku]}"
      url_params += "&amount_#{counter}=#{item[:amount]}"
      url_params += "&quantity_#{counter}=1"
      counter += 1
    end
    
    url = URI.escape(payment_method.preferences["sandbox_url"] + url_params)
    redirect_to(url)
  end

  # Inbound post from PayPal after (possible) successful completion
  def paypal_confirm
    load_order
    if(@order.completed_at && @order.state == "paid")
      order_params = {:checkout_complete => true}
      session[:order_id] = nil
      redirect_to(order_url(@order, {:checkout_complete => true, :order_token => @order.token}))
    else
      render(:partial => "shared/paypal_standard_pending", :layout => true)
    end
  end

  private

  def redirect_to_paypal_standard_form_if_needed
    return unless params[:state] == "payment"

    load_order

    # a bit of a hack because in production params[:order] stragely disappears
    if params[:order] && params[:order][:payments_attributes]#.first[:payment_method_id]
      payment_method = PaymentMethod.find(params[:order][:payments_attributes].first[:payment_method_id])
    else
      payment_method = PaymentMethod.find_by_type("PaymentMethod::PaypalStandard")
    end

    if(payment_method.kind_of?(PaymentMethod::PaypalStandard))
      redirect_to(paypal_payment_order_checkout_url(@order, :payment_method_id => payment_method))
    end
  end

  def fixed_opts
    { :description             => Spree::Config[:site_name], # site details...
      :background_color        => "ffffff",  # must be hex only, six chars
      :header_background_color => "ffffff",
      :header_border_color     => "ffffff",
      :allow_note              => true,
      :locale                  => Spree::Config[:default_locale],
      :req_confirm_shipping    => false,   # for security, might make an option later
    }
  end

  def order_opts(order, payment_method, stage)
    items = order.line_items.map do |item|
      { :name        => item.variant.product.name,
        :description => item.variant.product.description[0..120],
        :sku         => item.variant.sku,
        :qty         => item.quantity,
        :amount      => item.price,
        :weight      => item.variant.weight,
        :height      => item.variant.height,
        :width       => item.variant.width,
        :depth       => item.variant.weight }
    end

    #add each credit a line item to ensure totals sum up correctly
    credits = order.adjustments.map do |credit|
      { :name        => credit.label,
        :description => credit.label,
        :sku         => credit.id,
        :qty         => 1,
        :amount      => (credit.amount*100).to_i }
    end

#    items.concat credits

    opts = { 
      :return_url        => request.protocol + request.host_with_port + "/orders/#{order.number}/checkout/paypal_confirm?payment_method_id=#{payment_method}", 
      :cancel_return_url => "http://"  + request.host_with_port + "/orders/#{order.number}/edit",
      :order_id          => order.number,
      :custom            => order.number,
      :items             => items
    }

    if stage == "checkout"
      # recalculate all totals here as we need to ignore shipping & tax because we are checking-out via paypal (spree checkout not started)

      # get the main totals from the items (already *100)
      opts[:subtotal] = opts[:items].map {|i| i[:amount] * i[:qty] }.sum
      #opts[:tax]      = opts[:items].map {|i| i[:tax]    * i[:qty] }.sum
      opts[:handling] = 0
      opts[:shipping] = (order.ship_total*100).to_i

      # overall total
      opts[:money]    = opts.slice(:subtotal, :tax, :shipping, :handling).values.sum

      opts[:callback_url] = "http://"  + request.host_with_port + "/paypal_standard_callbacks/#{order.number}"

    elsif  stage == "payment"
      #use real totals are we are paying via paypal (spree checkout almost complete)
      opts[:subtotal] = ((order.item_total * 100) + (order.adjustments.total * 100)).to_i
      opts[:tax]      = (order.tax_total*100).to_i
      opts[:shipping] = (order.ship_total*100).to_i

      #hack to add float rounding difference in as handling fee - prevents PayPal from rejecting orders
      #becuase the integer totals are different from the float based total. This is temporary and will be
      #removed once Spree's currency values are persisted as integers (normally only 1c)
      opts[:handling] =  (order.total*100).to_i - opts.slice(:subtotal, :tax, :shipping).values.sum

      opts[:money] = (order.total*100).to_i
    end

    opts
  end

  def all_opts(order, payment_method, stage=nil)
    opts = fixed_opts.merge(order_opts(order, payment_method, stage))
    # suggest current user's email or any email stored in the order
    opts[:email] = current_user ? current_user.email : order.checkout.email
    opts
  end

  # create the gateway from the supplied options
  def payment_method
    PaymentMethod.find(params[:payment_method_id])
  end

end
