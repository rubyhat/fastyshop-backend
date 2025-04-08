# frozen_string_literal: true

module Api
  module V1
    class SellerProfilesController < BaseController
      skip_before_action :authenticate_user!, only: [ :show, :show_by_user ]

      # GET /api/v1/seller_profiles
      def index
        user = current_user
        return render_unauthorized unless user

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

        render json: profile, status: :ok
      end



      # GET /api/v1/seller_profiles/:id
      def show
        profile = SellerProfile.find_by(id: params[:id])
        return render_not_found unless profile

        render json: profile, status: :ok
      end

      # POST /api/v1/seller_profiles
      def create
        user = current_user

        return render_error(
          key: "seller_profiles.already_exists",
          message: "Профиль уже существует",
          status: :unprocessable_entity,
          code: 422
        ) if user && user.seller_profile.present?

        if user
          profile = user.build_seller_profile(seller_profile_params)

          if profile.save
            render json: profile, status: :created
          else
            render_validation_errors(profile)
          end
        end
      end

      # PATCH /api/v1/seller_profiles/:id
      def update
        user = current_user
        profile = SellerProfile.find_by(id: params[:id])
        return render_not_found unless profile
        return render_forbidden unless user && profile.user_id == user.id

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
