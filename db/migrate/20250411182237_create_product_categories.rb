class CreateProductCategories < ActiveRecord::Migration[7.1]
  def change
    create_table :product_categories, id: :uuid do |t|
      t.references :shop, null: false, foreign_key: true, type: :uuid
      t.string :title, null: false
      t.string :slug, null: false
      t.uuid :parent_id, null: true
      t.integer :level, null: false, default: 0
      t.integer :position, null: false, default: 0
      t.boolean :is_active, null: false, default: true

      t.timestamps
    end

    add_index :product_categories, :title
    add_index :product_categories, :parent_id
    add_index :product_categories, :level
    add_index :product_categories, :position
    add_index :product_categories, :is_active
  end
end
