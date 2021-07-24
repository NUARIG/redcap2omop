class AddDeletedInNextDataDictionaryToRedcapVariableChoices < ActiveRecord::Migration[6.1]
  def change
    add_column :redcap2omop_redcap_variable_choices, :deleted_in_next_data_dictionary, :boolean, null: true
  end
end
