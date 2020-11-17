class CreateRedcapEventMaps < ActiveRecord::Migration[6.0]
  def change
    create_table :redcap_event_maps do |t|
      t.integer :redcap_event_id,   null: false
      t.integer :concept_id,        null: true
      t.datetime :deleted_at,       null: true

      t.timestamps
    end
  end
end
