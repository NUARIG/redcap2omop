class CreateOmopCdm < ActiveRecord::Migration[6.0]
  def change
    #Compile OMOP tables
    ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']

    `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel-5.3.1/PostgreSQL/OMOP CDM postgresql ddl.sql"`
  end
end
