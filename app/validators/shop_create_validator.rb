# frozen_string_literal: true

class ShopCreateValidator < ActiveModel::Validator
  MAX_SHOPS = 2 # TODO: заменить на значение из тарифа

  def validate(record)
    validate_shop_limit(record)
    validate_seller_profile(record)
    validate_legal_profile(record)
    validate_legal_profile_ownership(record)
  end

  private

  def validate_shop_limit(record)
    return unless record.seller_profile

    if record.seller_profile.shops.count >= MAX_SHOPS
      record.errors.add(:base, "Достигнуто максимальное количество магазинов по Вашему тарифу")
    end
  end

  def validate_seller_profile(record)
    unless record.seller_profile
      record.errors.add(:base, "Чтобы создать магазин, необходим профиль продавца")
    end
  end

  def validate_legal_profile(record)
    unless record.legal_profile
      record.errors.add(:base, "Чтобы создать магазин, необходимо создать юридический профиль")
    end
  end

  def validate_legal_profile_ownership(record)
    legal_profile = record.legal_profile
    seller_profile = record.seller_profile

    unless legal_profile && seller_profile && legal_profile.seller_profile_id == seller_profile.id
      record.errors.add(:legal_profile_id, "Вы не можете использовать чужой юридический профиль")
    end
  end
end
