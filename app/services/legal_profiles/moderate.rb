# frozen_string_literal: true

module LegalProfiles
  # Moderate applies approve/reject transitions to legal profile verification.
  class Moderate
    ALLOWED_TARGET_STATUSES = %w[approved rejected].freeze

    # @param legal_profile [LegalProfile]
    # @param actor [User]
    # @param target_status [String, Symbol]
    # @param comment [String, nil]
    def initialize(legal_profile:, actor:, target_status:, comment: nil)
      @legal_profile = legal_profile
      @actor = actor
      @target_status = target_status.to_s
      @comment = comment.to_s.strip.presence
    end

    # @return [LegalProfile]
    def call
      unless ALLOWED_TARGET_STATUSES.include?(target_status)
        legal_profile.errors.add(:verification_status, "недопустимый целевой статус модерации")
        return legal_profile
      end

      unless legal_profile.pending_review?
        legal_profile.errors.add(:verification_status, "модерация доступна только для профиля на ручной проверке")
        return legal_profile
      end

      from_status = legal_profile.verification_status

      ActiveRecord::Base.transaction do
        legal_profile.update!(
          verification_status: target_status,
          moderation_comment: comment
        )

        legal_profile.record_verification_event!(
          event_type: target_status,
          actor_user: actor,
          from_status: from_status,
          to_status: legal_profile.verification_status,
          comment: comment
        )
      end

      legal_profile
    rescue ActiveRecord::RecordInvalid => e
      e.record
    end

    private

    attr_reader :legal_profile, :actor, :target_status, :comment
  end
end
