# frozen_string_literal: true

module Api
  module V1
    class SellerProfilesController < BaseController
      # GET /api/v1/seller_profiles
      def index
        authorize SellerProfile, :index?
        profiles = policy_scope(SellerProfile)
        render json: profiles, status: :ok
      end

      # GET /api/v1/users/:user_id/seller_profile
      def show_by_user
        user = User.find_by(id: params[:user_id])
        return render_not_found unless user

        profile = user.seller_profile
        return render_not_found unless profile

        authorize profile, :show?
        render json: profile, status: :ok
      end

      # GET /api/v1/seller_profiles/:id
      def show
        profile = SellerProfile.find_by(id: params[:id])
        return render_not_found unless profile

        authorize profile, :show?
        render json: profile, status: :ok
      end

      # POST /api/v1/seller_profiles
      def create
        user = current_user
        authorize SellerProfile, :create?

        if user.seller_profile.present?
          return render_error(
            key: "seller_profiles.already_exists",
            message: "Профиль уже существует",
            status: :unprocessable_entity,
            code: 422
          )
        end

        profile = SellerProfiles::Create.new(user: user, attributes: seller_profile_params).call

        if profile.persisted?
          render json: profile, status: :created
        else
          render_validation_errors(profile)
        end
      end


      # PATCH /api/v1/seller_profiles/:id
      def update
        profile = SellerProfile.find_by(id: params[:id])
        return render_not_found unless profile

        authorize profile, :update?

        if profile.update(seller_profile_params)
          render json: profile, status: :ok
        else
          render_validation_errors(profile)
        end
      end

      private

      def seller_profile_params
        params.permit(:display_name, :description, :logo_url)
      end
    end
  end
end
