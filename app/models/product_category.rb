# frozen_string_literal: true

# Модель категории или подкатегории товара/услуги внутри магазина.
class ProductCategory < ApplicationRecord
  belongs_to :shop
  belongs_to :parent, class_name: "ProductCategory", optional: true
  belongs_to :published_by, class_name: "User", optional: true
  belongs_to :archived_by, class_name: "User", optional: true

  has_many :children,
           class_name: "ProductCategory",
           foreign_key: :parent_id,
           dependent: :restrict_with_error,
           inverse_of: :parent
  has_many :products, dependent: :restrict_with_error
  has_many :lifecycle_events,
           as: :record,
           class_name: "CatalogLifecycleEvent",
           dependent: :destroy,
           inverse_of: :record

  enum :status, {
    draft: 0,
    published: 1,
    archived: 2
  }, default: :draft

  before_validation :assign_level
  before_validation :generate_slug, on: [ :create, :update ]
  before_validation :assign_position, on: :create
  after_create :record_created_lifecycle_event

  validates :title, presence: true, length: { maximum: 100 }
  validates :slug, presence: true, length: { maximum: 200 }
  validates :level, numericality: { greater_than_or_equal_to: 0 }
  validates :position, numericality: { greater_than_or_equal_to: 0 }

  validate :parent_belongs_to_same_shop
  validate :parent_is_not_self_or_descendant
  validate :archived_records_are_read_only, on: :update

  validates_with ProductCategoryBaseValidator
  validates_with ProductCategoryCreateValidator, on: :create
  validates_with ProductCategoryUpdateValidator, on: :update

  before_destroy :prevent_destroy

  # @return [Array<String>]
  def descendant_ids
    ids = []
    frontier = [ id ].compact

    while frontier.any?
      child_ids = self.class.where(parent_id: frontier).pluck(:id)
      ids.concat(child_ids)
      frontier = child_ids
    end

    ids
  end

  # @return [ActiveRecord::Relation<ProductCategory>]
  def descendants
    self.class.where(id: descendant_ids)
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

  def assign_level
    self.level = parent.present? ? parent.level.to_i + 1 : 0
  end

  def generate_slug
    return if title.blank? || shop.blank?

    base_slug = title.to_s.parameterize(locale: :ru)[0..99].presence || "category"
    candidate = base_slug
    counter = 1

    while shop.product_categories.where.not(id: id).exists?(slug: candidate)
      counter += 1
      candidate = "#{base_slug}-#{counter}"
    end

    self.slug = candidate
  end

  def assign_position
    return if shop.blank?

    siblings = shop.product_categories.where(parent_id: parent_id)
    self.position = siblings.count + 1
  end

  def parent_belongs_to_same_shop
    return if parent.blank? || shop.blank?

    errors.add(:parent_id, "должна принадлежать тому же магазину") if parent.shop_id != shop.id
  end

  def parent_is_not_self_or_descendant
    return if parent_id.blank? || id.blank?

    if parent_id == id || descendant_ids.include?(parent_id)
      errors.add(:parent_id, "не может ссылаться на саму категорию или её потомка")
    end
  end

  def archived_records_are_read_only
    return unless archived?
    return if restoring_from_archive?

    allowed_changes = %w[status archived_at archived_by_id updated_at]
    changed_fields = changed_attribute_names_to_save - allowed_changes
    return if changed_fields.empty?

    errors.add(:base, "Архивированную категорию нельзя редактировать. Сначала восстановите её из архива.")
  end

  def restoring_from_archive?
    will_save_change_to_status? && status == "draft"
  end

  def prevent_destroy
    errors.add(:base, "Категорию нельзя удалить полностью. Используйте архивирование.")
    throw :abort
  end

  def record_created_lifecycle_event
    record_lifecycle_event!(event_type: :created, actor_user: Current.user)
  end
end
