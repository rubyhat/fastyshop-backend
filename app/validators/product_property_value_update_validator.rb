# frozen_string_literal: true

class ProductPropertyValueUpdateValidator < ActiveModel::Validator
  def validate(record)
    if record.product_property&.source_type == "global"
      record.errors.add(:base, "Нельзя редактировать значения системных свойств")
    end
  end
end
