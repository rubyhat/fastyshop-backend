# frozen_string_literal: true

class ProductCreateValidator < ActiveModel::Validator
  MAX_PRODUCTS_PER_SHOP = 100 # пока захардкожено, потом по тарифу

  def validate(record)
    return unless record.shop

    if record.shop.products.count >= MAX_PRODUCTS_PER_SHOP
      record.errors.add(:base, "Превышен лимит товаров/услуг для магазина (максимум #{MAX_PRODUCTS_PER_SHOP})")
    end
  end
end
