# frozen_string_literal: true

# todo: добавить удаление, когда будут магазины
module Api
  module V1
    class LegalProfilesController < BaseController
      before_action :set_seller_profile, only: [ :create ]
      skip_before_action :authenticate_user!, only: [ :show ]

      # GET /api/v1/legal_profiles
      def index
        user = current_user
        return render_unauthorized unless user

        authorize LegalProfile, :index?
        legal_profiles = policy_scope(LegalProfile)
        render json: legal_profiles, status: :ok
      end

      # GET /api/v1/legal_profiles/:id
      def show
        profile = LegalProfile.find_by(id: params[:id])
        return render_not_found unless profile

        render json: profile, status: :ok
      end

      # POST /api/v1/legal_profiles
      def create
        user = current_user
        return render_unauthorized unless user

        unless @seller_profile
          return render_error(
            key: "legal_profiles.no_seller_profile",
            message: "У вас нет профиля продавца",
            status: :forbidden,
            code: 403
          )
        end

        legal_profile = @seller_profile.legal_profiles.build(legal_profile_params)

        authorize legal_profile, :create?

        if legal_profile.save
          render json: legal_profile, status: :created
        else
          render_validation_errors(legal_profile)
        end
      end

      # PATCH /api/v1/legal_profiles/:id
      def update
        user = current_user
        return render_unauthorized unless user

        profile = LegalProfile.find_by(id: params[:id])
        return render_not_found unless profile

        authorize profile, :update?

        permitted_fields = permitted_update_fields(profile)
        if profile.update(params.permit(permitted_fields))
          render json: profile, status: :ok
        else
          render_validation_errors(profile)
        end
      end

      # PATCH /api/v1/legal_profiles/:id/unverify
      def unverify
        user = current_user
        return render_unauthorized unless user

        profile = LegalProfile.find_by(id: params[:id])
        return render_not_found unless profile

        authorize profile, :unverify?

        if profile.is_verified
          profile.update(is_verified: false)
          render json: profile, status: :ok
        else
          render_error(
            key: "legal_profiles.not_verified",
            message: "Профиль уже не верифицирован",
            status: :bad_request,
            code: 400
          )
        end
      end


      private

      def set_seller_profile
        user = current_user
        @seller_profile = user&.seller_profile
      end

      def legal_profile_params
        params.permit(
          :company_name,
          :tax_id,
          :country_code,
          :legal_address,
          :legal_form
        )
      end

      def permitted_update_fields(profile)
        user = current_user
        return [] unless user

        if user.superadmin? || user.supermanager?
          %i[company_name tax_id country_code legal_address legal_form is_verified]
        elsif profile.is_verified
          %i[legal_address] # только адрес можно редактировать
        else
          %i[company_name tax_id country_code legal_address legal_form]
        end
      end
    end
  end
end
