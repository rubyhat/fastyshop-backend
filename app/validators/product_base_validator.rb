# frozen_string_literal: true

class ProductBaseValidator < ActiveModel::Validator
  def validate(record)
    validate_slug_uniqueness(record)
  end

  private

  def validate_slug_uniqueness(record)
    return if record.slug.blank? || record.shop.blank?

    scope = record.shop.products.where(slug: record.slug)
    scope = scope.where.not(id: record.id) if record.persisted?

    if scope.exists?
      record.errors.add(:slug, "должен быть уникальным в пределах магазина")
    end
  end
end
