# frozen_string_literal: true

module Api
  module V1
    module Public
      class LegalProfilesController < ApplicationController
        include ApiErrorHandling

        # GET /api/v1/public/legal_profiles/:id/transparency
        def transparency
          legal_profile = ::LegalProfile.includes(:seller_profile, :shops).find_by(id: params[:id])
          return render_not_found unless legal_profile

          render json: {
            seller: PublicSellerProfileSerializer.new(legal_profile.seller_profile).as_json,
            legal_profile: PublicLegalProfileTransparencySerializer.new(legal_profile).as_json,
            related_shops: ActiveModelSerializers::SerializableResource.new(
              legal_profile.shops.active,
              each_serializer: RelatedShopTransparencySerializer
            ).as_json
          }, status: :ok
        end
      end
    end
  end
end
