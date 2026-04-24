# frozen_string_literal: true

class ProductCategoryCreateValidator < ActiveModel::Validator
  def validate(_record)
    # Tariff-based category limits will be implemented in a separate billing task.
  end
end
