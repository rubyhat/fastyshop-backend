# frozen_string_literal: true

class ProductCreateValidator < ActiveModel::Validator
  def validate(_record)
    # Tariff-based product limits will be implemented in a separate billing task.
  end
end
