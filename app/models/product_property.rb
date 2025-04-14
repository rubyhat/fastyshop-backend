# frozen_string_literal: true

# Характеристика товара или услуги, создаваемая продавцом или системой.
#
# @!attribute id [r] UUID характеристики
# @!attribute user_id [rw] UUID владельца (null — если глобальное свойство)
# @!attribute title [rw] Название характеристики
# @!attribute value_type [rw] Тип значения: строка, число, булево
# @!attribute source_type [rw] Источник: пользовательское или глобальное
# @!attribute created_at [r]
# @!attribute updated_at [r]
#
class ProductProperty < ApplicationRecord
  belongs_to :user, optional: true

  # has_many :product_property_values, dependent: :destroy
  # has_many :product_property_shop_category_templates, dependent: :destroy

  enum :value_type, {
    string: 0,
    number: 1,
    boolean: 2
  }

  enum :source_type, {
    user: 0,
    global: 1
  }

  validates_with ProductPropertyBaseValidator
  validates_with ProductPropertyCreateValidator, on: :create
  validates_with ProductPropertyUpdateValidator, on: :update

  validates :title, presence: true, length: { maximum: 100 }
  validates :value_type, presence: true
  validates :source_type, presence: true

  validates :title, uniqueness: {
    scope: %i[user_id source_type],
    case_sensitive: false,
    message: "уже существует среди ваших или глобальных характеристик"
  }
end
