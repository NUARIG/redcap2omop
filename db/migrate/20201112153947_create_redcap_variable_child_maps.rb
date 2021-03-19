class CreateRedcapVariableChildMaps < ActiveRecord::Migration[6.0]
  def change
    create_table :redcap_variable_child_maps do |t|
      t.integer :redcap_variable_id,          null: true
      t.integer :parentable_id,               null: false
      t.string  :parentable_type,             null: false
      t.integer :omop_column_id,              null: true
      t.timestamps
      t.datetime :deleted_at,     null: true
    end
  end
end