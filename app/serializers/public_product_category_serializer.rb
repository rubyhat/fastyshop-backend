# frozen_string_literal: true

class PublicProductCategorySerializer < ActiveModel::Serializer
  attributes :id,
             :title,
             :slug,
             :parent_id,
             :position,
             :children

  # @return [Array<Hash>]
  def children
    object.children.published.order(:position, :created_at).map do |child|
      PublicProductCategorySerializer.new(child).as_json
    end
  end
end
