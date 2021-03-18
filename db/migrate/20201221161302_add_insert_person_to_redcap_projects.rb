class AddInsertPersonToRedcapProjects < ActiveRecord::Migration[6.1]
  def change
    add_column :redcap2omop_redcap_projects, :insert_person, :boolean
  end
end
