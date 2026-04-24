# frozen_string_literal: true

module LegalProfiles
  # SubmitVerification sends the legal profile to manual review.
  class SubmitVerification
    # @param legal_profile [LegalProfile]
    # @param actor [User]
    def initialize(legal_profile:, actor:)
      @legal_profile = legal_profile
      @actor = actor
    end

    # @return [LegalProfile]
    def call
      unless legal_profile.draft? || legal_profile.rejected?
        legal_profile.errors.add(:verification_status, "профиль можно отправить на проверку только из статуса черновика или отклонения")
        return legal_profile
      end

      from_status = legal_profile.verification_status

      ActiveRecord::Base.transaction do
        legal_profile.update!(
          verification_status: :pending_review,
          moderation_comment: nil
        )

        legal_profile.record_verification_event!(
          event_type: :submitted,
          actor_user: actor,
          from_status: from_status,
          to_status: legal_profile.verification_status
        )
      end

      legal_profile
    rescue ActiveRecord::RecordInvalid => e
      e.record
    end

    private

    attr_reader :legal_profile, :actor
  end
end
