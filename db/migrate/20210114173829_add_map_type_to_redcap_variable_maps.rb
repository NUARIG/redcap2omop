class AddMapTypeToRedcapVariableMaps < ActiveRecord::Migration[6.0]
  def change
    add_column :redcap_variable_maps, :map_type, :string
  end
end
