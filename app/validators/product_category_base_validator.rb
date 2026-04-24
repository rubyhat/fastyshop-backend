# frozen_string_literal: true

class ProductCategoryBaseValidator < ActiveModel::Validator
  def validate(record)
    validate_slug_uniqueness(record)
    validate_parent_exists(record)
  end

  private

  def validate_slug_uniqueness(record)
    return if record.slug.blank? || record.shop.blank?

    scope = record.shop.product_categories.where(slug: record.slug)
    scope = scope.where.not(id: record.id) if record.persisted?

    record.errors.add(:slug, "должен быть уникальным в пределах магазина") if scope.exists?
  end

  def validate_parent_exists(record)
    return if record.parent_id.blank?

    unless record.shop&.product_categories&.exists?(id: record.parent_id)
      record.errors.add(:parent_id, "указана несуществующая родительская категория")
    end
  end
end
