# frozen_string_literal: true

class PublicShopChangeEventSerializer < ActiveModel::Serializer
  attributes :event_type,
             :occurred_at,
             :summary,
             :changes

  # @return [Time]
  def occurred_at
    object.created_at
  end

  # @return [String]
  def summary
    object.public_summary
  end

  # @return [Hash]
  def changes
    object.public_changes
  end
end
