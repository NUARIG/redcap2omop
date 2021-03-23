class ChangeColumnNullRedcapProjectsApiToken < ActiveRecord::Migration[6.1]
  def change
    change_column_null :redcap2omop_redcap_projects, :api_token, true
  end
end
