# frozen_string_literal: true

module SolidusMollie
  module Spree
    # Intercepts the checkout confirm step. When the order is paying with a
    # Mollie payment method, the buyer is redirected to Mollie's hosted checkout
    # instead of the order being completed synchronously. The order is finished
    # later by the webhook (see SolidusMollie::ProcessWebhook).
    module CheckoutControllerDecorator
      def update
        return redirect_to_mollie if divert_to_mollie?

        super
      end

      private

      def divert_to_mollie?
        return false unless params[:state].to_s == 'confirm' || @order&.confirm?

        mollie_payment.present?
      end

      def mollie_payment
        @mollie_payment ||= @order&.payments&.detect do |payment|
          payment.checkout? && payment.payment_method.is_a?(SolidusMollie::PaymentMethod)
        end
      end

      def redirect_to_mollie
        result = SolidusMollie::CreateOrderPayment.call(
          order: @order,
          payment: mollie_payment,
          redirect_url: spree.mollie_return_url(mollie_url_options.merge(
                                                  order_number: @order.number,
                                                  token: @order.token
                                                )),
          webhook_url: spree.mollie_webhook_url(mollie_url_options)
        )

        if result.success?
          redirect_to result.checkout_url, allow_other_host: true
        else
          flash[:error] = I18n.t('solidus_mollie.payment_error',
                                 message: result.error,
                                 default: "We couldn't start your Mollie payment.")
          redirect_to spree.checkout_state_path(:payment)
        end
      end

      def mollie_url_options
        {
          host: request.host,
          port: request.optional_port,
          protocol: request.ssl? ? 'https' : 'http'
        }.compact
      end
    end
  end
end
