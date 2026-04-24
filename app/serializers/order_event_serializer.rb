# frozen_string_literal: true

class OrderEventSerializer < ActiveModel::Serializer
  attributes :id,
             :event_type,
             :from_status,
             :to_status,
             :comment,
             :actor_user_id,
             :created_at
end
