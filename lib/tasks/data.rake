require 'csv'
namespace :redcap2omop do
  namespace :data do
    desc "Compile OMOP tables"
    task(compile_omop_tables: :environment) do  |t, args|
      Redcap2omop::Setup.compile_omop_tables
    end

    desc "Compile OMOP table extensions"
    task(compile_omop_table_extensions: :environment) do  |t, args|
      Redcap2omop::Setup.compile_omop_table_extensions
    end

    desc "Load OMOP vocabulary tables"
    task(load_omop_vocabulary_tables: :environment) do  |t, args|
      Redcap2omop::Setup.load_omop_vocabulary_tables
    end

    desc "Compile OMOP vocabulary indexes"
    task(compile_omop_vocabulary_indexes: :environment) do  |t, args|
      Redcap2omop::Setup.compile_omop_vocabulary_indexes
    end

    desc "Compile OMOP indexes"
    task(compile_omop_indexes: :environment) do  |t, args|
      Redcap2omop::Setup.compile_omop_indexes
    end

    desc "Compile OMOP constraints"
    task(compile_omop_constraints: :environment) do  |t, args|
      Redcap2omop::Setup.compile_omop_constraints
    end

    desc "Drop OMOP vocabulary indexes"
    task(drop_omop_vocabulary_indexes: :environment) do  |t, args|
      Redcap2omop::Setup.drop_omop_vocabulary_indexes
    end

    desc "Drop OMOP indexes"
    task(drop_omop_indexes: :environment) do  |t, args|
      Redcap2omop::Setup.drop_omop_indexes
    end

    desc "Drop OMOP constraints"
    task(drop_omop_constraints: :environment) do  |t, args|
      Redcap2omop::Setup.drop_omop_constraints
    end

    desc "Drop all tables"
    task(drop_all_tables: :environment) do  |t, args|
      Redcap2omop::Setup.drop_all_tables
    end

    desc "Truncate clinical data tables"
    task(truncate_omop_clinical_data_tables: :environment) do  |t, args|
      Redcap2omop::Setup.truncate_omop_clinical_data_tables
    end

    desc "Truncate vocabulary tables"
    task(truncate_omop_vocabulary_tables: :environment) do  |t, args|
      Redcap2omop::Setup.truncate_omop_vocabulary_tables
    end
  end
end
