# frozen_string_literal: true

# Сериалайзер для категории/подкатегории товаров или услуг.
#
# Возвращает структуру, пригодную для построения дерева категорий.
#
# @return [JSON]
#   - :id—UUID категории
#   - :title — название
#   - :slug — слаг
#   - :level — уровень вложенности
#   - :position — порядковый номер
#   - :is_active — флаг активности
#   - :parent_id — UUID родительской категории
#   - :shop_id — UUID магазина
#   - :children — подкатегории (рекурсивно)
#
class ProductCategorySerializer < ActiveModel::Serializer
  attributes :id, :title, :slug, :level, :position, :is_active, :parent_id, :shop_id

  has_many :children, serializer: ProductCategorySerializer
end
