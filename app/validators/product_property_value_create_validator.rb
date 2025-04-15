# frozen_string_literal: true

class ProductPropertyValueCreateValidator < ActiveModel::Validator
  MAX_VALUES_PER_PRODUCT = 10 #  todo: хардкод, в будущем будет зависеть от тарифного плана

  def validate(record)
    return unless record.product.present?

    if record.product.product_property_values.size >= MAX_VALUES_PER_PRODUCT
      record.errors.add(:base, "Достигнуто максимальное количество свойств на продукт")
    end
  end
end
