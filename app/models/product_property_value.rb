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

  validates_with ProductPropertyValueBaseValidator
  validates_with ProductPropertyValueCreateValidator, on: :create
  validates_with ProductPropertyValueUpdateValidator, on: :update


  validates :value, presence: true
  validates :product_id, uniqueness: { scope: :product_property_id, message: "значение свойства уже задано" }
end
