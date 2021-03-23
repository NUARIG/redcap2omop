class AddMapTypeToRedcapVariableMaps < ActiveRecord::Migration[6.0]
  def change
    add_column :redcap2omop_redcap_variable_maps, :map_type, :string, null: false
  end
end
