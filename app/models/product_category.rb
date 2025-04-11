# frozen_string_literal: true

# Модель категории или подкатегории товара/услуги.
#
# @!attribute id [r] UUID категории
# @!attribute shop_id [rw] UUID магазина, к которому принадлежит категория
# @!attribute title [rw] Название категории
# @!attribute slug [rw] Генерируется из title
# @!attribute parent_id [rw] UUID родительской категории (null для корневых)
# @!attribute level [rw] Уровень вложенности (0 — корневая)
# @!attribute position [rw] Порядок отображения
# @!attribute is_active [rw] Флаг активности
# @!attribute created_at [r] Дата создания
# @!attribute updated_at [r] Дата последнего обновления
#
class ProductCategory < ApplicationRecord
  belongs_to :shop
  belongs_to :parent, class_name: "ProductCategory", optional: true
  has_many :children, class_name: "ProductCategory", foreign_key: :parent_id, dependent: :destroy

  validates :title, presence: true, length: { maximum: 100 }
  validates :level, inclusion: { in: 0..3 }
  validates :position, numericality: { greater_than_or_equal_to: 0 }

  validate :shop_category_limit

  private

  # Ограничивает общее количество категорий и подкатегорий в рамках одного магазина (до 20)
  def shop_category_limit
    return if shop.nil?

    existing_count = shop.product_categories.count
    if new_record? && existing_count >= 20
      errors.add(:base, "Превышено максимальное количество категорий и подкатегорий в магазине (20)")
    end
  end
end
