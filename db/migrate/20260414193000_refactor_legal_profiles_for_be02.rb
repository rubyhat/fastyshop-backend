class RefactorLegalProfilesForBe02 < ActiveRecord::Migration[8.1]
  def up
    add_column :legal_profiles, :legal_name, :string
    add_column :legal_profiles, :legal_form_code, :string
    add_column :legal_profiles, :registration_number_type, :string
    add_column :legal_profiles, :registration_number, :string
    add_column :legal_profiles, :verification_status, :integer, null: false, default: 0
    add_column :legal_profiles, :moderation_comment, :text

    execute <<~SQL.squish
      UPDATE legal_profiles
      SET legal_name = company_name,
          legal_form_code = 'limited_liability_partnership',
          registration_number_type = 'bin',
          registration_number = regexp_replace(tax_id, '\\D', '', 'g'),
          verification_status = CASE
            WHEN is_verified = TRUE THEN 2
            ELSE 0
          END
    SQL

    change_column_null :legal_profiles, :legal_name, false
    change_column_null :legal_profiles, :legal_form_code, false
    change_column_null :legal_profiles, :registration_number_type, false
    change_column_null :legal_profiles, :registration_number, false

    remove_index :legal_profiles, :tax_id, if_exists: true
    add_index :legal_profiles, %i[country_code registration_number_type registration_number],
              unique: true,
              name: "index_legal_profiles_on_country_type_and_registration_number"
    add_index :legal_profiles, :verification_status

    create_table :legal_profile_verification_events, id: :uuid do |t|
      t.references :legal_profile, null: false, type: :uuid, foreign_key: true
      t.references :actor_user, null: true, type: :uuid, foreign_key: { to_table: :users }
      t.integer :event_type, null: false
      t.string :from_status
      t.string :to_status
      t.text :comment
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :legal_profile_verification_events, %i[legal_profile_id created_at],
              name: "idx_lp_verif_events_on_profile_created"

    remove_column :legal_profiles, :company_name
    remove_column :legal_profiles, :tax_id
    remove_column :legal_profiles, :legal_form
    remove_column :legal_profiles, :is_verified
  end

  def down
    add_column :legal_profiles, :company_name, :string, null: false, default: ""
    add_column :legal_profiles, :tax_id, :string, null: false, default: ""
    add_column :legal_profiles, :legal_form, :string, null: false, default: ""
    add_column :legal_profiles, :is_verified, :boolean, default: false

    execute <<~SQL.squish
      UPDATE legal_profiles
      SET company_name = legal_name,
          tax_id = registration_number,
          legal_form = legal_form_code,
          is_verified = CASE
            WHEN verification_status = 2 THEN TRUE
            ELSE FALSE
          END
    SQL

    drop_table :legal_profile_verification_events

    remove_index :legal_profiles, name: "index_legal_profiles_on_country_type_and_registration_number", if_exists: true
    remove_index :legal_profiles, :verification_status, if_exists: true

    remove_column :legal_profiles, :moderation_comment
    remove_column :legal_profiles, :verification_status
    remove_column :legal_profiles, :registration_number
    remove_column :legal_profiles, :registration_number_type
    remove_column :legal_profiles, :legal_form_code
    remove_column :legal_profiles, :legal_name

    remove_index :legal_profiles, :tax_id, if_exists: true
    add_index :legal_profiles, :tax_id, unique: true
  end
end
