class AddRedcapDerivedDateIdToRedcapVariableChildMaps < ActiveRecord::Migration[6.0]
  def change
    add_column :redcap2omop_redcap_variable_child_maps, :redcap_derived_date_id, :integer, null: true
  end
end
