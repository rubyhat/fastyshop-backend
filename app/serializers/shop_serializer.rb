class ShopSerializer < ActiveModel::Serializer
  attributes :id,
             :title,
             :slug,
             :canonical_path,
             :description,
             :logo_url,
             :contact_phone,
             :contact_email,
             :physical_address,
             :shop_type,
             :status,
             :status_comment,
             :verified_badge,
             :slug_policy

  belongs_to :seller_profile, serializer: ShopSellerProfileSerializer
  belongs_to :legal_profile, serializer: ShopLegalProfileSerializer
  belongs_to :shop_category, serializer: ShopCategoryShortSerializer
end
