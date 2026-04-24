# frozen_string_literal: true

# Модель товара, цифрового товара или услуги внутри магазина.
class Product < ApplicationRecord
  belongs_to :shop
  belongs_to :product_category, optional: true
  belongs_to :published_by, class_name: "User", optional: true
  belongs_to :archived_by, class_name: "User", optional: true

  has_many :product_property_values, dependent: :destroy
  has_many :lifecycle_events,
           as: :record,
           class_name: "CatalogLifecycleEvent",
           dependent: :destroy,
           inverse_of: :record

  enum :product_type, {
    physical: 0,
    digital: 1,
    service: 2
  }

  enum :status, {
    draft: 0,
    published: 1,
    archived: 2
  }, default: :draft

  before_validation :generate_slug, on: :create
  before_validation :assign_position, on: :create
  after_create :record_created_lifecycle_event

  validates_with ProductBaseValidator
  validates_with ProductCreateValidator, on: :create
  validates_with ProductUpdateValidator, on: :update

  validates :title, presence: true, length: { maximum: 150 }
  validates :slug, presence: true, length: { maximum: 200 }
  validates :description, length: { maximum: 5000 }, allow_blank: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :product_type, presence: true
  validates :status, presence: true
  validates :position, numericality: { greater_than_or_equal_to: 0 }
  validates :stock_quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :sku, length: { maximum: 100 }, allow_blank: true
  validates :image_url, length: { maximum: 500 }, allow_blank: true

  validate :category_belongs_to_same_shop
  validate :category_must_be_published_for_publish
  validate :archived_records_are_read_only, on: :update

  before_destroy :prevent_destroy

  # @return [String]
  def availability
    return "unavailable" unless published? && shop&.active?
    return "out_of_stock" if physical? && stock_quantity.to_i <= 0

    "available"
  end

  # @return [Boolean]
  def available_for_cart?
    availability == "available"
  end

  # @return [Hash, nil]
  def unavailable_reason
    case availability
    when "available"
      nil
    when "out_of_stock"
      {
        key: "cart.item.out_of_stock",
        message: "Товара нет в наличии"
      }
    else
      {
        key: "cart.item.product_unavailable",
        message: "Товар больше недоступен"
      }
    end
  end

  # @param event_type [Symbol, String]
  # @param actor_user [User, nil]
  # @param metadata [Hash]
  # @return [CatalogLifecycleEvent]
  def record_lifecycle_event!(event_type:, actor_user:, metadata: {})
    lifecycle_events.create!(
      event_type: event_type,
      actor_user: actor_user,
      metadata: metadata
    )
  end

  private

  def generate_slug
    return if title.blank? || shop.blank?

    base_slug = title.to_s.parameterize(locale: :ru)[0..99].presence || "product"
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

  def category_belongs_to_same_shop
    return if product_category.blank? || shop.blank?

    errors.add(:product_category_id, "должна принадлежать тому же магазину") if product_category.shop_id != shop.id
  end

  def category_must_be_published_for_publish
    return unless published?
    return if product_category.blank?
    return if product_category.published?

    errors.add(:product_category_id, "должна быть опубликована перед публикацией товара")
  end

  def archived_records_are_read_only
    return unless archived?
    return if restoring_from_archive?

    allowed_changes = %w[status archived_at archived_by_id updated_at]
    changed_fields = changed_attribute_names_to_save - allowed_changes
    return if changed_fields.empty?

    errors.add(:base, "Архивированный товар нельзя редактировать. Сначала восстановите его из архива.")
  end

  def restoring_from_archive?
    will_save_change_to_status? && status == "draft"
  end

  def prevent_destroy
    errors.add(:base, "Товар нельзя удалить полностью. Используйте архивирование.")
    throw :abort
  end

  def record_created_lifecycle_event
    record_lifecycle_event!(event_type: :created, actor_user: Current.user)
  end
end
