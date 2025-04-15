# frozen_string_literal: true

class ProductPropertyValueBaseValidator < ActiveModel::Validator
  def validate(record)
    validate_value_type(record)
    validate_uniqueness(record)
  end

  private

  def validate_value_type(record)
    return if record.product_property.blank?

    case record.product_property.value_type
    when "number"
      unless record.value.to_s.match?(/\A-?\d+(\.\d+)?\z/)
        record.errors.add(:value, "должно быть числом")
      end
    when "boolean"
      unless %w[true false 1 0].include?(record.value.to_s.strip.downcase)
        record.errors.add(:value, "должно быть true/false или 1/0")
      end
    when "string"
      # не проверяем, строка всегда валидна
    else
      record.errors.add(:value, "неподдерживаемый тип")
    end
  end

  def validate_uniqueness(record)
    return if record.product.blank? || record.product_property.blank?

    existing = ProductPropertyValue
                 .where(product_id: record.product.id, product_property_id: record.product_property.id)
                 .where.not(id: record.id)
                 .exists?

    if existing
      record.errors.add(:base, "Значение этого свойства уже задано для продукта")
    end
  end
end
