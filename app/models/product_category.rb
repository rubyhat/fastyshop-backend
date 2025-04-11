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
  validates :slug, presence: true, length: { maximum: 200 }
  validates :level, inclusion: { in: 0..3 }
  validates :position, numericality: { greater_than_or_equal_to: 0 }

  validates_with ProductCategoryBaseValidator
  validates_with ProductCategoryCreateValidator, on: :create
  validates_with ProductCategoryUpdateValidator, on: :update

  private

  def generate_slug
    return if slug.present? && slug_changed?
    base_slug = title.parameterize[0..99]
    candidate = base_slug
    counter = 1

    while shop&.product_categories&.where&.not(id: id)&.exists?(slug: candidate) do
      counter += 1
      candidate = "#{base_slug}-#{counter}"
    end

    self.slug = candidate
  end
end
