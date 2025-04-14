# frozen_string_literal: true

# Значение свойства, привязанное к конкретному товару/услуге
#
# @!attribute id [r] UUID значения
# @!attribute product_id [rw] UUID продукта
# @!attribute product_property_id [rw] UUID свойства
# @!attribute value [rw] Значение свойства
# @!attribute created_at [r]
# @!attribute updated_at [r]
#
class ProductPropertyValue < ApplicationRecord
  belongs_to :product
  belongs_to :product_property

  validates :value, presence: true
  validates :product_id, uniqueness: { scope: :product_property_id, message: "значение свойства уже задано" }

  validate :value_type_must_match

  private

  def value_type_must_match
    return if product_property.blank?

    case product_property.value_type
    when "number"
      errors.add(:value, "должно быть числом") unless value.to_s.match?(/\A-?\d+(\.\d+)?\z/)
    when "boolean"
      unless %w[true false 1 0].include?(value.to_s.strip.downcase)
        errors.add(:value, "должно быть true/false или 1/0")
      end
    else
      # "Тип string не требует дополнительной валидации"
    end
  end
end
