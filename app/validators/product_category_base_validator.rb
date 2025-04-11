# frozen_string_literal: true

# Общий валидатор для ProductCategory.
#
# Используется как include внутри других валидаторов.
# Проверяет:
# - уровень вложенности (максимум 3)
# - уникальность slug в рамках магазина
# - существование родительской категории (если передан parent_id)
#
class ProductCategoryBaseValidator  < ActiveModel::Validator
  MAX_LEVEL = 3

  def validate(record)
    validate_level(record)
    validate_slug_uniqueness(record)
    validate_parent_exists(record)
  end

  private

  def validate_level(record)
    return if record.level.nil?

    if record.level > MAX_LEVEL
      record.errors.add(:level, "не может быть больше #{MAX_LEVEL}")
    end
  end

  def validate_slug_uniqueness(record)
    return if record.slug.blank? || record.shop.blank?

    scope = record.shop.product_categories.where(slug: record.slug)
    scope = scope.where.not(id: record.id) if record.persisted?

    if scope.exists?
      record.errors.add(:slug, "должен быть уникальным в пределах магазина")
    end
  end

  def validate_parent_exists(record)
    return if record.parent_id.blank?

    unless record.shop&.product_categories&.exists?(id: record.parent_id)
      record.errors.add(:parent_id, "указана несуществующая родительская категория")
    end
  end
end
