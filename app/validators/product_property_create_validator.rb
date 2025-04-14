class ProductPropertyCreateValidator < ActiveModel::Validator
  MAX_PROPERTIES_PER_USER = 50 # todo: временный хардкод, будет зависеть от тарифного плана

  def validate(record)
  end

  def product_property_limit?(record)
    return unless record.user.present?

    if record.user.product_properties.count >= MAX_PROPERTIES_PER_USER
      record.errors.add(:base, "Превышен лимит свойств по Вашему тарифному плану (#{MAX_PROPERTIES_PER_USER}шт.)")
    end
  end
end
