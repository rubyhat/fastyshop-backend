# frozen_string_literal: true

require "pp"
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

  before_validation :assign_level
  before_validation :generate_slug, on: [ :create, :update ]
  before_validation :assign_position, on: :create

  validates :title, presence: true, length: { maximum: 100 }
  validates :slug, presence: true, length: { maximum: 200 }
  validates :level, inclusion: { in: 0..3 }
  validates :position, numericality: { greater_than_or_equal_to: 0 }

  validates_with ProductCategoryBaseValidator
  validates_with ProductCategoryCreateValidator, on: :create
  validates_with ProductCategoryUpdateValidator, on: :update

  private

  # Вычисляет уровень вложенности на основе родительской категории.
  def assign_level
    self.level = parent.present? ? parent.level + 1 : 0
  end

  # Генерирует уникальный slug на основе title в рамках магазина.
  def generate_slug
    pp "enter in generate slug 1"
    pp title
    pp shop
    return if title.blank? || shop.blank?
    pp "Enter in generate slug 2"
    base_slug = title.to_s.parameterize[0..99] # todo: работает только с en, для ru, kz нужно добавить обработку
    candidate = base_slug
    counter = 1

    while shop.product_categories.where.not(id: id).exists?(slug: candidate)
      counter += 1
      candidate = "#{base_slug}-#{counter}"
    end
    pp candidate
    self.slug = candidate
  end

  # Автоматически задаёт позицию (в конец siblings).
  def assign_position
    return if shop.blank?

    siblings = shop.product_categories.where(parent_id: parent_id)
    self.position = siblings.count + 1
  end
end
