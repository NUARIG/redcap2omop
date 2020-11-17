class CreateRedcapVariables < ActiveRecord::Migration[6.0]
  def change
    create_table :redcap_variables do |t|
      t.integer :redcap_data_dictionary_id,  null: false
      t.string  :name,                       null: false
      t.string  :form_name,                  null: false
      t.string  :field_type,                 null: false
      t.string  :field_type_normalized,      null: false
      t.text    :field_label,                null: false
      t.text    :choices,                    null: true
      t.string  :text_validation_type,       null: true
      t.string  :field_annotation,           null: true
      t.decimal :ordinal_position,           null: true
      t.boolean :curated,                    null: true
      t.timestamps
      t.datetime :deleted_at, null: true
    end
  end
end