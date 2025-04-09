class CreateShopCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :shop_categories, id: :uuid do |t|
      t.string :title, null: false # Отображаемое имя
      t.string :name, null: false # Уникальный ключ
      t.text :description
      t.string :icon
      t.integer :position
      t.boolean :is_active, null: false, default: true

      t.timestamps
    end

    add_index :shop_categories, :name, unique: true
    add_index :shop_categories, :is_active
    add_index :shop_categories, :position
  end
end
