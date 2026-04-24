# frozen_string_literal: true

class PublicShopLegalDetailsSerializer < ActiveModel::Serializer
  attributes :shop,
             :legal_profile,
             :related_shops,
             :history

  # @return [Hash]
  def shop
    {
      title: object.title,
      slug: object.slug
    }
  end

  # @return [Hash]
  def legal_profile
    {
      legal_name: object.legal_profile.legal_name,
      legal_form_code: object.legal_profile.legal_form_code,
      legal_form_label: object.legal_profile.legal_form_label,
      verification_status: object.legal_profile.verification_status,
      registration_number_type: object.legal_profile.registration_number_type,
      registration_number_public: object.legal_profile.registration_number_public,
      legal_address_public: object.legal_profile.legal_address_public
    }
  end

  # @return [Array<Hash>]
  def related_shops
    object.legal_profile.shops.active.includes(:legal_profile).map do |shop|
      {
        title: shop.title,
        slug: shop.slug,
        verified_badge: shop.verified_badge
      }
    end
  end

  # @return [Array<Hash>]
  def history
    shop_events = object.change_events.order(created_at: :desc).limit(20).map do |event|
      PublicShopChangeEventSerializer.new(event).as_json
    end

    legal_events = object.legal_profile.verification_events.order(created_at: :desc).limit(20).map do |event|
      {
        event_type: event.event_type,
        occurred_at: event.created_at,
        summary: legal_event_summary(event)
      }
    end

    (shop_events + legal_events).sort_by { |event| event[:occurred_at] }.reverse.first(20)
  end

  private

  def legal_event_summary(event)
    case event.event_type
    when "approved"
      "Юридический профиль подтверждён"
    when "rejected"
      "Юридический профиль отклонён"
    when "submitted"
      "Юридический профиль отправлен на проверку"
    else
      "Изменён статус юридического профиля"
    end
  end
end
