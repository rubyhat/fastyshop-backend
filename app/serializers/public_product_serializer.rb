# frozen_string_literal: true

class PublicProductSerializer < ActiveModel::Serializer
  attributes :id,
             :title,
             :slug,
             :description,
             :price,
             :product_type,
             :category,
             :availability,
             :stock_state,
             :image_url

  # @return [Hash, nil]
  def category
    return nil unless object.product_category

    {
      id: object.product_category.id,
      title: object.product_category.title,
      slug: object.product_category.slug
    }
  end

  # @return [String]
  def stock_state
    object.availability == "out_of_stock" ? "out_of_stock" : "in_stock"
  end
end
