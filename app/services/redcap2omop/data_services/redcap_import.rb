module Redcap2omop::DataServices
  class RedcapImport
    attr_reader :redcap_project

    def initialize(redcap_project:)
      @redcap_project   = redcap_project
    end

    def run
      ActiveRecord::Base.transaction do
        raise 'project api token is missing' if redcap_project.api_token.blank?

        redcap_webservice = Redcap2omop::Webservices::RedcapApi.new(api_token: redcap_project.api_token)
        records_response = redcap_webservice.records
        raise "error retrieving records from REDCap: #{records_response[:error]}" if records_response[:error]

        records     = records_response[:response]
        field_names = records.first.keys
        refresh_redcap_export_table(redcap_project.export_table_name, field_names)
        load_redcap_records(redcap_project.export_table_name, records)
      end
      OpenStruct.new(success: true)
    rescue Exception => exception
      OpenStruct.new(success: false, message: exception.message, backtrace: exception.backtrace.join("\n"))
    end

    # private

    def refresh_redcap_export_table(export_table_name, field_names)
      sql = generate_create_redcap_export_table_sql(export_table_name, field_names)
      ActiveRecord::Base.connection.execute "DROP TABLE IF EXISTS #{export_table_name}"
      ActiveRecord::Base.connection.execute sql
    end

    def generate_create_redcap_export_table_sql(export_table_name, field_names)
      sql = "CREATE TABLE #{export_table_name}"
      sql_fields = []
      field_names.each do |field_name|
        # sql_fields << "#{field_name} VARCHAR(255)"
        if field_name == 'redcap_repeat_instance'
          sql_fields << "#{field_name} INTEGER"
        else
          sql_fields << "#{field_name} VARCHAR"
        end
      end
      sql << " (#{sql_fields.join(',')})"
    end

    def load_redcap_records(export_table_name, records)
      records.each do |record|
        values = record.map{ |k,v| k != 'redcap_repeat_instance' ? ActiveRecord::Base.connection.quote(v) : v.blank? ? 'null' : v }.join(',')
        ActiveRecord::Base.connection.exec_insert(
          "INSERT INTO #{export_table_name} (#{record.keys.join(',')}) VALUES (#{values})"
        )
      end
    end
  end
end
