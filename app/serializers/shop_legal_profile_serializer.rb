# frozen_string_literal: true

class ShopLegalProfileSerializer < ActiveModel::Serializer
  attributes :id,
             :legal_name,
             :legal_form_code,
             :legal_form_label,
             :registration_number_type,
             :registration_number_public,
             :verification_status
end
