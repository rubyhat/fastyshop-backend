# frozen_string_literal: true

module Api
  module V1
    class LegalProfilesController < BaseController
      before_action :set_seller_profile, only: [ :create ]

      # GET /api/v1/legal_profiles
      def index
        authorize LegalProfile, :index?
        legal_profiles = policy_scope(LegalProfile)
        render json: legal_profiles, status: :ok
      end

      # GET /api/v1/legal_profiles/:id
      def show
        profile = LegalProfile.find_by(id: params[:id])
        return render_not_found unless profile

        authorize profile, :show?
        render json: profile, status: :ok
      end

      # POST /api/v1/legal_profiles
      def create
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
        profile = LegalProfile.find_by(id: params[:id])
        return render_not_found unless profile

        authorize profile, :update?

        profile = LegalProfiles::Update.new(
          legal_profile: profile,
          attributes: params.permit(*permitted_update_fields(profile)),
          actor: current_user
        ).call

        if profile.errors.empty?
          render json: profile, status: :ok
        else
          render_validation_errors(profile)
        end
      end

      # POST /api/v1/legal_profiles/:id/submit_verification
      def submit_verification
        profile = LegalProfile.find_by(id: params[:id])
        return render_not_found unless profile

        authorize profile, :submit_verification?

        profile = LegalProfiles::SubmitVerification.new(
          legal_profile: profile,
          actor: current_user
        ).call

        if profile.errors.empty?
          render json: profile, status: :ok
        else
          render_validation_errors(profile)
        end
      end

      # POST /api/v1/legal_profiles/:id/approve
      def approve
        moderate!(:approved)
      end

      # POST /api/v1/legal_profiles/:id/reject
      def reject
        moderate!(:rejected)
      end

      # GET /api/v1/legal_profiles/:id/verification_events
      def verification_events
        profile = LegalProfile.find_by(id: params[:id])
        return render_not_found unless profile

        authorize profile, :verification_events?

        render json: profile.verification_events.order(:created_at), status: :ok
      end

      private

      def moderate!(target_status)
        profile = LegalProfile.find_by(id: params[:id])
        return render_not_found unless profile

        authorize profile, target_status == :approved ? :approve? : :reject?

        profile = LegalProfiles::Moderate.new(
          legal_profile: profile,
          actor: current_user,
          target_status: target_status,
          comment: moderation_params[:comment]
        ).call

        if profile.errors.empty?
          render json: profile, status: :ok
        else
          render_validation_errors(profile)
        end
      end

      def set_seller_profile
        user = current_user
        @seller_profile = user&.seller_profile
      end

      def legal_profile_params
        params.permit(
          :country_code,
          :legal_form_code,
          :legal_name,
          :registration_number_type,
          :registration_number,
          :legal_address,
        )
      end

      def permitted_update_fields(profile)
        user = current_user
        return [] unless user

        if user.superadmin? || user.supermanager? || profile.seller_profile_id == user.seller_profile&.id
          %i[
            country_code
            legal_form_code
            legal_name
            registration_number_type
            registration_number
            legal_address
          ]
        else
          []
        end
      end

      def moderation_params
        params.permit(:comment)
      end
    end
  end
end
