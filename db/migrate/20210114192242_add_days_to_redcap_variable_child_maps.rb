class AddDaysToRedcapVariableChildMaps < ActiveRecord::Migration[6.0]
  def change
    add_column :redcap_variable_child_maps, :days, :integer
  end
end
