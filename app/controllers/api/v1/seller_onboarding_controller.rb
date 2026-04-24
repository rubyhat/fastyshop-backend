# frozen_string_literal: true

module Api
  module V1
    class SellerOnboardingController < BaseController
      # POST /api/v1/seller_onboarding
      def create
        authorize :seller_onboarding, :create?

        result = SellerOnboarding::Create.new(
          user: current_user,
          seller_profile_attributes: seller_profile_params,
          legal_profile_attributes: legal_profile_params,
          shop_attributes: shop_params
        ).call

        if result.success?
          render json: {
            seller_profile: SellerProfileSerializer.new(result.seller_profile).as_json,
            legal_profile: LegalProfileSerializer.new(result.legal_profile).as_json,
            shop: ShopSerializer.new(result.shop).as_json
          }, status: :created
        else
          render_validation_errors(result.error_record)
        end
      end

      private

      def seller_profile_params
        params.require(:seller_profile).permit(:display_name, :description, :logo_url)
      end

      def legal_profile_params
        params.require(:legal_profile).permit(
          :country_code,
          :legal_form_code,
          :legal_name,
          :registration_number_type,
          :registration_number,
          :legal_address
        )
      end

      def shop_params
        params.require(:shop).permit(
          :title,
          :slug,
          :description,
          :logo_url,
          :contact_phone,
          :contact_email,
          :shop_category_id,
          :physical_address,
          :shop_type
        )
      end
    end
  end
end
