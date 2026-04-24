# frozen_string_literal: true

class PublicSellerProfileSerializer < ActiveModel::Serializer
  attributes :display_name, :slug, :logo_url, :description
end
