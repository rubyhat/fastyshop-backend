# frozen_string_literal: true

class ShopSellerProfileSerializer < ActiveModel::Serializer
  attributes :id, :display_name, :slug, :logo_url
end
