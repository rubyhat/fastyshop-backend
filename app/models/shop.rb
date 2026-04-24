class Shop < ApplicationRecord
  SLUG_FORMAT = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/
  TRUST_CRITICAL_FIELDS = %w[
    title
    slug
    contact_phone
    contact_email
    physical_address
    legal_profile_id
  ].freeze

  belongs_to :seller_profile
  belongs_to :legal_profile
  belongs_to :shop_category
  has_many :product_categories, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :slug_histories,
           class_name: "ShopSlugHistory",
           dependent: :destroy,
           inverse_of: :shop
  has_many :change_events,
           class_name: "ShopChangeEvent",
           dependent: :destroy,
           inverse_of: :shop

  enum :shop_type, {
    online: 1,
    offline: 2,
    hybrid: 3
  }

  enum :status, {
    active: 0,
    disabled_by_owner: 1,
    suspended_by_admin: 2
  }, default: :active

  before_validation :normalize_slug

  validates :title, presence: true, length: { maximum: 100 }
  validates :slug,
            presence: true,
            length: { minimum: 3, maximum: 50 },
            format: {
              with: SLUG_FORMAT,
              message: "может содержать только латинские строчные буквы, цифры и дефис без двойных или крайних дефисов"
            },
            uniqueness: { case_sensitive: false }
  validates :description, length: { maximum: 2000 }, allow_blank: true
  validates :logo_url, length: { maximum: 500 }, allow_blank: true
  validates :contact_phone, presence: true, length: { maximum: 32 }
  validates :contact_email, allow_blank: true, length: { maximum: 100 }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :physical_address, allow_blank: true, length: { maximum: 255 }
  validates :shop_type, presence: true
  validates :status, presence: true
  validates :status_comment, length: { maximum: 2000 }, allow_blank: true

  validate :slug_not_reserved_by_another_shop
  validate :slug_not_blocked_for_new_value
  validate :legal_profile_belongs_to_seller_profile

  validates_with ShopCreateValidator, on: :create

  # @return [Boolean]
  def verified_badge
    legal_profile&.verified_badge? || false
  end

  # @return [String]
  def canonical_path
    "/shops/#{slug}"
  end

  # @return [String]
  def content_state
    active? ? "visible" : "hidden"
  end

  # @return [Boolean]
  def storefront_content_visible?
    active?
  end

  # @return [String, nil]
  def physical_address_public
    return nil if online?

    physical_address
  end

  # @return [Hash, nil]
  def public_alert
    if disabled_by_owner?
      {
        key: "shops.public.disabled_by_owner",
        message: "Владелец временно отключил этот магазин"
      }
    elsif suspended_by_admin?
      {
        key: "shops.public.suspended_by_admin",
        message: "Магазин временно отключён платформой"
      }
    end
  end

  # @return [Hash]
  def slug_policy
    blocked_entry = SlugBlocklistEntry.matching(slug).first

    {
      current_slug_allowed: blocked_entry.blank?,
      action_required: blocked_entry.present?,
      reason: blocked_entry&.public_reason
    }
  end

  private

  def normalize_slug
    self.slug = slug.to_s.strip.downcase if slug.present?
  end

  def slug_not_reserved_by_another_shop
    return if slug.blank?

    conflict_exists = ShopSlugHistory.where(slug: slug).where.not(shop_id: id).exists?
    errors.add(:slug, "уже использовался другим магазином") if conflict_exists
  end

  def slug_not_blocked_for_new_value
    return if slug.blank?
    return unless new_record? || will_save_change_to_slug?

    blocked_entry = SlugBlocklistEntry.matching(slug).first
    return unless blocked_entry

    errors.add(:slug, blocked_entry.public_reason)
  end

  def legal_profile_belongs_to_seller_profile
    return if legal_profile.blank? || seller_profile.blank?

    unless legal_profile.seller_profile_id == seller_profile.id
      errors.add(:legal_profile_id, "Вы не можете использовать чужой юридический профиль")
    end
  end
end
