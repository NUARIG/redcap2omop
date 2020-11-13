class CreateRedcapVariableMaps < ActiveRecord::Migration[6.0]
  def change
    create_table :redcap_variable_maps do |t|
      t.integer :redcap_variable_id,   null: false
      t.integer :concept_id,           null: true
      t.integer :omop_column_id,       null: true
      t.timestamps
      t.datetime :deleted_at,     null: true
    end
  end
end