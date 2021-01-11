class ChangeColumnNullRedcapProjectsApiToken < ActiveRecord::Migration[6.0]
  def change
    change_column_null :redcap_projects, :api_token, true
  end
end
