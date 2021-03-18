class CreateRedcapDataDictionaries < ActiveRecord::Migration[6.1]
  def change
    create_table :redcap2omop_redcap_data_dictionaries do |t|
      t.integer :redcap_project_id,  null: false
      t.integer :version,            null: false
      t.timestamps
      t.datetime :deleted_at,        null: true
    end
  end
end
