class ShopSerializer < ActiveModel::Serializer
  attributes :id,
             :title,
             :slug,
             :contact_phone,
             :contact_email,
             :physical_address,
             :is_active,
             :shop_type

  belongs_to :seller_profile, serializer: ShopSellerProfileSerializer
  belongs_to :legal_profile, serializer: ShopLegalProfileSerializer
  belongs_to :shop_category, serializer: ShopCategoryShortSerializer
end
