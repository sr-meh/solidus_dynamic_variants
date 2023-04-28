# frozen_string_literal: true

class DynamicCartLineItemsController < Spree::StoreController
  helper 'spree/products', 'spree/orders'

  respond_to :html

  before_action :store_guest_token

  # Adds a new item to the order (creating a new order if none already exists)
  # creates a dynamic variant on the fly
  def create
    @order = current_order(create_order_if_necessary: true)
    authorize! :update, @order, cookies.signed[:guest_token]
    product = ::Spree::Product.find(params[:product_id])
    option_values_ids = params[:options].present? ? params[:options].values : []
    option_values = ::Spree::OptionValue.where(id: option_values_ids)
    variant = product.try_variant option_values
    quantity = params[:quantity].present? ? params[:quantity].to_i : 1

    # 2,147,483,647 is crazy. See issue https://github.com/spree/spree/issues/2695.
    if !quantity.between?(1, 2_147_483_647)
      @order.errors.add(:base, t('spree.please_enter_reasonable_quantity'))
    else
      begin
        @line_item = @order.contents.add(variant, quantity)
      rescue ActiveRecord::RecordInvalid => error
        @order.errors.add(:base, error.record.errors.full_messages.join(", "))
      end
    end

    respond_with(@order) do |format|
      format.html do
        if @order.errors.any?
          flash[:error] = @order.errors.full_messages.join(", ")
          redirect_back_or_default(root_path)
          return
        else
          redirect_to edit_cart_path
        end
      end
    end
  end

  private

  def store_guest_token
    cookies.permanent.signed[:guest_token] = params[:token] if params[:token]
  end
end
