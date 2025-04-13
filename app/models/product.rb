# frozen_string_literal: true

# Модель товара или услуги
#
# @!attribute id [r] UUID продукта
# @!attribute shop_id [rw] UUID магазина
# @!attribute product_category_id [rw] UUID категории (необязательно для услуг)
# @!attribute title [rw] Название
# @!attribute slug [rw] Уникальный идентификатор на основе названия
# @!attribute description [rw] Описание
# @!attribute price [rw] Стоимость
# @!attribute product_type [rw] Тип (товар или услуга)
# @!attribute is_active [rw] Статус отображения
# @!attribute position [rw] Порядок сортировки
# @!attribute created_at [r]
# @!attribute updated_at [r]
#
class Product < ApplicationRecord
  belongs_to :shop
  belongs_to :product_category, optional: true

  # has_many :product_property_values, dependent: :destroy

  enum :product_type, { product: 0, service: 1 }

  before_validation :generate_slug, on: :create
  before_validation :assign_position, on: :create

  validates_with ProductBaseValidator
  validates_with ProductCreateValidator, on: :create
  validates_with ProductUpdateValidator, on: :update
  validates_with ProductDestroyValidator, on: :destroy

  validates :title, presence: true, length: { maximum: 150 }
  validates :slug, presence: true, length: { maximum: 200 }
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :product_type, presence: true
  validates :position, numericality: { greater_than_or_equal_to: 0 }

  private

  def generate_slug
    return if title.blank? || shop.blank?

    base_slug = title.to_s.parameterize(locale: :ru)[0..99]
    candidate = base_slug
    counter = 1

    while shop.products.where.not(id: id).exists?(slug: candidate)
      counter += 1
      candidate = "#{base_slug}-#{counter}"
    end

    self.slug = candidate
  end

  def assign_position
    return if shop.blank?

    siblings = shop.products.where(product_category_id: product_category_id)
    self.position = siblings.count + 1
  end
end
