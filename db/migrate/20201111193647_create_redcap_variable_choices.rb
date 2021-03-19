class CreateRedcapVariableChoices < ActiveRecord::Migration[6.0]
  def change
    create_table :redcap_variable_choices do |t|
      t.integer :redcap_variable_id,                null: false
      t.string  :choice_code_raw,                   null: false
      t.string  :choice_code_concept_code,          null: true
      t.string  :choice_description,                null: false
      t.string  :vocabulary_id_raw,                 null: true
      t.string  :vocabulary_id,                     null: true
      t.string  :map_choice,                        null: true
      t.string  :choice_code_value_as_concept_code, null: true
      t.string  :value_as_vocabualry_id,            null: true
      t.decimal :ordinal_position,                  null: false
      t.string  :curation_status,                   null: false
      t.timestamps
      t.datetime :deleted_at, null: true
    end
  end
end