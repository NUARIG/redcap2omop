class AddRouteToObservationToRedcapProjects < ActiveRecord::Migration[6.0]
  def change
    add_column :redcap_projects, :route_to_observation, :boolean
  end
end
