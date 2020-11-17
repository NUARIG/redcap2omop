class CreateRedcapEvents < ActiveRecord::Migration[6.0]
  def change
    create_table :redcap_events do |t|
      t.string :event_name,                 null: false
      t.integer :arm_num,                   null: false
      t.integer :day_offset,                null: false
      t.integer :offset_min,                null: false
      t.integer :offset_max,                null: false
      t.string :unique_event_name,          null: false
      t.string :custom_event_label,         null: true
      t.datetime :deleted_at,               null: true

      t.timestamps
    end
  end
end
