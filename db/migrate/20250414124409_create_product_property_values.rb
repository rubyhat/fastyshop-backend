class CreateProductPropertyValues < ActiveRecord::Migration[8.0]
  def change
    create_table :product_property_values, id: :uuid do |t|
      t.references :product, null: false, foreign_key: true, type: :uuid
      t.references :product_property, null: false, foreign_key: true, type: :uuid

      t.string :value, null: false

      t.timestamps
    end
    add_index :product_property_values, [ :product_id, :product_property_id ], unique: true
  end
end
