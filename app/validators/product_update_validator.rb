# frozen_string_literal: true

class ProductUpdateValidator < ActiveModel::Validator
  def validate(_record)
    # Пока нет логики, но зарезервировано под:
    # - контроль тарифов и доступных опций
  end
end
