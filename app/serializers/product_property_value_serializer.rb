# frozen_string_literal: true

class ProductPropertyValueSerializer < ActiveModel::Serializer
  attributes :id, :value, :product_id, :product_property_id,
             :created_at, :updated_at

  # belongs_to :product_property, serializer: ProductPropertyCompactSerializer
  attribute :product_property do
    ProductPropertyCompactSerializer.new(object.product_property, scope: scope).as_json
  end
end
