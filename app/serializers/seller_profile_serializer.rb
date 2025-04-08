# app/serializers/seller_profile_serializer.rb
class SellerProfileSerializer < ActiveModel::Serializer
  attributes :id, :display_name, :slug, :description, :logo_url, :user_id, :created_at
end
