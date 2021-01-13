class AddCurationStatusToRedcapVariables < ActiveRecord::Migration[6.0]
  def change
    add_column :redcap_variables, :curation_status, :string
  end
end
