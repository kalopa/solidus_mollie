# frozen_string_literal: true

module SolidusMollie
  # Handles the two requests Mollie sends us:
  #   * #webhook  - server-to-server POST with the payment id (source of truth)
  #   * #return   - the buyer's browser coming back from Mollie's hosted page
  class CallbacksController < ::Spree::StoreController
    skip_before_action :verify_authenticity_token, only: :webhook

    # POST /mollie/webhook  (body: id=tr_xxxxx)
    def webhook
      SolidusMollie::ProcessWebhook.call(mollie_payment_id: params[:id])
      head :ok
    rescue SolidusMollie::ProcessWebhook::PaymentNotFound => e
      # 422 so Mollie retries (covers the rare webhook-before-persist race).
      Rails.logger.warn("[solidus_mollie] webhook payment not found: #{e.message}")
      head :unprocessable_entity
    rescue StandardError => e
      Rails.logger.error("[solidus_mollie] webhook error: #{e.message}")
      head :internal_server_error
    end

    # GET /mollie/return?order_number=R123&token=abc
    def return
      order = ::Spree::Order.find_by!(number: params[:order_number])

      if params[:token].present? && order.token.present? &&
         !ActiveSupport::SecurityUtils.secure_compare(params[:token].to_s, order.token.to_s)
        raise ActiveRecord::RecordNotFound
      end

      unless order.completed?
        flash[:notice] = I18n.t('solidus_mollie.confirming_payment',
                                default: "Thanks! We're confirming your payment with Mollie.")
      end

      redirect_to spree.order_url(order, token: order.token)
    rescue ActiveRecord::RecordNotFound
      flash[:error] = I18n.t('solidus_mollie.order_not_found', default: 'Order not found.')
      redirect_to spree.root_path
    end
  end
end
