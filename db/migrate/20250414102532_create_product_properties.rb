class CreateProductProperties < ActiveRecord::Migration[8.0]
  def change
    create_table :product_properties, id: :uuid do |t|
      t.references :user,  null: false, foreign_key: true, type: :uuid
      t.string :title, null: false
      t.integer :value_type, null: false
      t.integer :source_type, null: false

      t.timestamps
    end

    add_index :product_properties, :source_type
    add_index :product_properties, [ :user_id, :title, :source_type ], unique: true
  end
end
