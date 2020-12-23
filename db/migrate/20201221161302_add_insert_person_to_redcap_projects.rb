class AddInsertPersonToRedcapProjects < ActiveRecord::Migration[6.0]
  def change
    add_column :redcap_projects, :insert_person, :boolean
  end
end
