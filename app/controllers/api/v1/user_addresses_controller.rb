# frozen_string_literal: true

require "pp"
module Api
  module V1
    class UserAddressesController < BaseController
      before_action :authenticate_user!
      before_action :set_address, only: %i[ show update destroy]

      # GET /api/v1/user_addresses
      def index
        user = current_user
        render_unauthorized unless user

        addresses = policy_scope(user&.user_addresses|| []).order(created_at: :desc)
        render json: addresses, status: :ok
      end

      # GET /api/v1/user_addresses/:id
      def show
        authorize @address
        render json: @address, status: 200
      end

      # POST /api/v1/user_addresses
      def create
        user = current_user
        return render_unauthorized unless user

        new_address = user.user_addresses.new(address_params)
        authorize new_address

        if new_address.save
          render json: new_address, status: 201
        else
          render_validation_errors(new_address)
        end
      end

      # PATCH /api/v1/user_addresses/:id
      def update
        authorize @address

        if @address.update(address_params)
          render json: @address, status: 200
        else
          render_validation_errors(@address)
        end
      end

      # DELETE /api/v1/user_addresses/:id
      def destroy
        authorize @address
        if @address.destroy
          render_success(
            key: "user_address.success_destroy",
            message: "Адрес успешно удален",
            code: :ok
          )
        else
          render_validation_errors(@address)
        end
      end

      private

      def address_params
        params.require(:user_address).permit(
          :label,
          :country_code,
          :city,
          :street,
          :house,
          :apartment,
          :postal_code,
          :contact_name,
          :contact_phone,
          :is_default,
          :description
        )
      end

      def set_address
        user = current_user
        return render_unauthorized unless user

        @address = user.user_addresses.find_by(id: params[:id])
        render_not_found unless @address
      end
    end
  end
end
