class CreateRedcapDerivedDateChoiceOffsetMappings < ActiveRecord::Migration[6.0]
  def change
    create_table :redcap_derived_date_choice_offset_mappings do |t|
      t.integer :offset_redcap_varaible_id,   null: false
      t.integer :redcap_variable_choice_id,   null: false
      t.integer :ofsset_days,                 null: false
    end
  end
end