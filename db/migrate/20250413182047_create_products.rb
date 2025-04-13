class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products, id: :uuid do  |t|
      t.references :shop, null: false, foreign_key: true, type: :uuid
      t.references :product_category, null: true, foreign_key: true, type: :uuid

      t.string :title, null: false
      t.string :slug, null: false
      t.text :description
      t.decimal :price, null: false, precision: 10, scale: 2

      t.integer :position, null: false
      t.integer :product_type, null: false
      t.boolean :is_active, default: true, null: false


      t.timestamps
    end

    add_index :products, :title
    add_index :products, :price
    add_index :products, :product_type
    add_index :products, :is_active
    add_index :products, [ :shop_id, :slug ], unique: true
  end
end
