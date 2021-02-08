class AddMapTypeToRedcapVariableChildMaps < ActiveRecord::Migration[6.0]
  def change
    add_column :redcap_variable_child_maps, :map_type, :string, null: false
  end
end
