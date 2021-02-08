class CreateRedcapDerivedDateChoiceOffsetMappings < ActiveRecord::Migration[6.0]
  def change
    create_table :redcap_derived_date_choice_offset_mappings do |t|
      t.integer :redcap_derived_date_id,      null: false
      t.integer :redcap_variable_choice_id,   null: false
      t.integer :offset_days,                 null: false
    end
  end
end