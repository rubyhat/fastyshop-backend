# frozen_string_literal: true

class ProductCompactSerializer < ActiveModel::Serializer
  attributes :id, :title, :slug, :price, :product_type, :status, :availability
end
