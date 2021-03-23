class AddApiImportToRedcapProjects < ActiveRecord::Migration[6.1]
  def change
    add_column :redcap2omop_redcap_projects, :api_import, :boolean
  end
end
