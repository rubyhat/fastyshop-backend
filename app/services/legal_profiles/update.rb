# frozen_string_literal: true

module LegalProfiles
  # Update applies legal profile changes and resets verification when critical fields change.
  class Update
    # @param legal_profile [LegalProfile]
    # @param attributes [Hash, ActionController::Parameters]
    # @param actor [User]
    def initialize(legal_profile:, attributes:, actor:)
      @legal_profile = legal_profile
      @attributes = attributes.to_h.deep_symbolize_keys
      @actor = actor
    end

    # @return [LegalProfile]
    def call
      from_status = legal_profile.verification_status
      should_reset = legal_profile.approved? && legal_profile.critical_fields_changed_for?(attributes)

      legal_profile.assign_attributes(attributes)

      if should_reset
        legal_profile.verification_status = :draft
        legal_profile.moderation_comment = nil
      end

      ActiveRecord::Base.transaction do
        legal_profile.save!

        if should_reset
          legal_profile.record_verification_event!(
            event_type: :reset_to_draft,
            actor_user: actor,
            from_status: from_status,
            to_status: legal_profile.verification_status
          )
        end
      end

      legal_profile
    rescue ActiveRecord::RecordInvalid => e
      e.record
    end

    private

    attr_reader :legal_profile, :attributes, :actor
  end
end
