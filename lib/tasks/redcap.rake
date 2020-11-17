require 'webservices/redcap_api'

namespace :redcap do
  desc "Reload Redcap data"
  task reload_exported_data: :environment do
    redcap_webservice = Webservices::RedcapApi.new
    records           = redcap_webservice.records

    field_names = records.first.keys
    refresh_redcap_export_table(field_names)
    load_redcap_records(records)
  end

  private
  def refresh_redcap_export_table(field_names)
    version = Time.now.strftime('%Y%m%d%H%M%S')
    generate_new_migration(version, field_names)
    run_new_migration(version)
  end

  def generate_new_migration(version, field_names)
    sql_fields = []
    field_names.each do |field_name|
      sql_fields << "t.string :#{field_name}"
    end

    migration_file = File.new( File.join(Rails.root, 'db', 'migrate', "#{version}_create_redcap_export_tmp_#{version}.rb"), 'w')
    migration_code = <<MIGRATION_CODE
class CreateRedcapExportTmp#{version} < ActiveRecord::Migration[6.0]
  def change
    connection.execute 'drop table if exists #{RedcapExportTmp.table_name}'
    create_table :#{RedcapExportTmp.table_name} do |t|
      #{sql_fields.join("\n\t\t\t")}

      t.timestamps
    end
  end
end
MIGRATION_CODE

    migration_file.write(migration_code)
    migration_file.close
  end

  def run_new_migration(version)
    `rails db:migrate:up VERSION=#{version}`
  end

  def load_redcap_records(records)
    records.each do |record|
      RedcapExportTmp.create(record)
    end
  end
end
