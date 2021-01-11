class AddApiImportToRedcapProjects < ActiveRecord::Migration[6.0]
  def change
    add_column :redcap_projects, :api_import, :boolean
  end
end
