# frozen_string_literal: true

# Валидатор при создании ProductCategory.
#
# Дополнительно к базовым проверкам:
# - Проверяет лимит в 20 категорий на магазин
#
class ProductCategoryCreateValidator < ActiveModel::Validator
  MAX_CATEGORIES_PER_SHOP = 20

  def validate(record)
    validate_category_limit(record)
  end

  private

  def validate_category_limit(record)
    return if record.shop.blank?

    if record.shop.product_categories.count >= MAX_CATEGORIES_PER_SHOP
      record.errors.add(:base, "Превышено максимальное количество категорий и подкатегорий (#{MAX_CATEGORIES_PER_SHOP})")
    end
  end
end
