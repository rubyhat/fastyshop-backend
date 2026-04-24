# frozen_string_literal: true

module Shops
  # Update applies shop changes and records only trust-critical public history.
  class Update
    Result = Struct.new(:shop, :error_record, keyword_init: true) do
      def success?
        error_record.nil?
      end
    end

    # @param shop [Shop]
    # @param actor_user [User, nil]
    # @param attributes [Hash, ActionController::Parameters]
    def initialize(shop:, actor_user:, attributes:)
      @shop = shop
      @actor_user = actor_user
      @attributes = attributes.to_h.deep_symbolize_keys
    end

    # @return [Result]
    def call
      ActiveRecord::Base.transaction do
        shop.update!(attributes)
        record_trust_events!
      end

      Result.new(shop: shop)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(shop: shop, error_record: e.record)
    end

    private

    attr_reader :shop, :actor_user, :attributes

    def record_trust_events!
      save_slug_history! if shop.saved_change_to_slug?
      record_title_change! if shop.saved_change_to_title?
      record_slug_change! if shop.saved_change_to_slug?
      record_contact_change! if contact_changes.present?
      record_legal_profile_change! if shop.saved_change_to_legal_profile_id?
    end

    def save_slug_history!
      old_slug, = shop.saved_change_to_slug
      return if old_slug.blank?

      shop.slug_histories.find_or_create_by!(slug: old_slug)
    end

    def record_title_change!
      from, to = shop.saved_change_to_title
      record_event!(:title_changed, from: from, to: to)
    end

    def record_slug_change!
      from, to = shop.saved_change_to_slug
      record_event!(:slug_changed, from: from, to: to)
    end

    def record_contact_change!
      record_event!(:contacts_changed, fields: contact_changes)
    end

    def record_legal_profile_change!
      from, to = shop.saved_change_to_legal_profile_id
      record_event!(
        :legal_profile_changed,
        from: legal_profile_label(from),
        to: legal_profile_label(to)
      )
    end

    def contact_changes
      @contact_changes ||= %w[contact_phone contact_email physical_address].each_with_object({}) do |field, changes|
        next unless shop.saved_change_to_attribute?(field)

        from, to = shop.saved_change_to_attribute(field)
        changes[field] = { from: from, to: to }
      end
    end

    def legal_profile_label(id)
      return nil if id.blank?

      LegalProfile.find_by(id: id)&.legal_name
    end

    def record_event!(event_type, changeset)
      shop.change_events.create!(
        event_type: event_type,
        actor_user: actor_user,
        changeset: changeset
      )
    end
  end
end
