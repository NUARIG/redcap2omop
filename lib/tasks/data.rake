# initial setup
# bundle exec rake db:migrate
# bundle exec rake data:load_omop_vocabulary_tables
# bundle exec rake data:compile_omop_vocabulary_indexes

# load data

# bundle exec rake data:compile_omop_indexes
# bundle exec rake data:compile_omop_constraints

# bundle exec rake data:drop_omop_constraints
# bundle exec rake data:drop_omop_indexes
# bundle exec rake data:drop_omop_vocabulary_indexes
# bundle exec rake data:drop_all_tables

require 'fileutils'
require 'csv'
namespace :data do
  desc "Compile OMOP tables"
  task(compile_omop_tables: :environment) do  |t, args|
    ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']

    `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel-5.3.1/PostgreSQL/OMOP CDM postgresql ddl.sql"`
  end

  desc "Load OMOP vocabulary tables"
  task(load_omop_vocabulary_tables: :environment) do  |t, args|
    file_name = "#{Rails.root}/db/migrate/CommonDataModel-5.3.1/PostgreSQL/VocabImport/OMOP CDM vocabulary load - PostgreSQL.sql.template"
    file_name_dest = file_name.gsub('.template','')
    FileUtils.cp(file_name, file_name_dest)
    text = File.read(file_name_dest)
    text = text.gsub(/RAILS_ROOT/, "#{Rails.root}")
    File.open(file_name_dest, "w") {|file| file.puts text }

    ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']
    `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel-5.3.1/PostgreSQL/VocabImport/OMOP CDM vocabulary load - PostgreSQL.sql"`
  end

  desc "Compile OMOP vocabulary indexes"
  task(compile_omop_vocabulary_indexes: :environment) do  |t, args|
    ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']
    `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel-5.3.1/PostgreSQL/OMOP CDM postgresql vocabulary indexes.sql"`
  end

  desc "Compile OMOP indexes"
  task(compile_omop_indexes: :environment) do  |t, args|
    ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']
    `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel-5.3.1/PostgreSQL/OMOP CDM postgresql indexes.sql"`
  end

  desc "Compile OMOP constraints"
  task(compile_omop_constraints: :environment) do  |t, args|
    ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']
    `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel-5.3.1/PostgreSQL/OMOP CDM postgresql constraints.sql"`
  end

  desc "Drop OMOP vocabulary indexes"
  task(drop_omop_vocabulary_indexes: :environment) do  |t, args|
    ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']
    `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel-5.3.1/PostgreSQL/DROP OMOP CDM postgresql vocabulary indexes.sql"`
  end

  desc "Drop OMOP indexes"
  task(drop_omop_indexes: :environment) do  |t, args|
    ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']
    `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel-5.3.1/PostgreSQL/DROP OMOP CDM postgresql indexes.sql"`
  end

  desc "Drop OMOP constraints"
  task(drop_omop_constraints: :environment) do  |t, args|
    ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']
      `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel-5.3.1/PostgreSQL/DROP OMOP CDM postgresql constraints.sql"`
  end

  desc "Drop all tables"
  task(drop_all_tables: :environment) do  |t, args|
    ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']

    `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel-5.3.1/PostgreSQL/DROP all tables ddl.sql"`
  end

  desc "Truncate clinical data tables"
  task(truncate_omop_clinical_data_tables: :environment) do  |t, args|
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE attribute_definition CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE care_site CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE cdm_source CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE cohort CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE cohort_attribute CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE cohort_definition CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE condition_era CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE condition_occurrence CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE cost CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE death CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE device_exposure CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE dose_era CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE drug_era CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE drug_exposure CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE fact_relationship CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE location CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE measurement CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE note CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE note_nlp CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE observation CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE observation_period CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE payer_plan_period CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE person CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE procedure_occurrence CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE provider CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE source_to_concept_map CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE specimen CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE visit_occurrence CASCADE;')
  end

  desc "Truncate vocabulary tables"
  task(truncate_omop_vocabulary_tables: :environment) do  |t, args|
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE concept CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE concept_ancestor CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE concept_class CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE concept_relationship CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE concept_synonym CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE domain CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE drug_strength CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE relationship CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE vocabulary CASCADE;')
  end
end