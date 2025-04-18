# frozen_string_literal: true

class ProductCompactSerializer < ActiveModel::Serializer
  attributes :id, :title, :price, :product_type
end
