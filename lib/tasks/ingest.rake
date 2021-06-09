require 'highline/import'

namespace :redcap2omop do
  namespace :ingest do
    namespace :data_dictionary do
      desc 'Cleanup data dictionaries'
      task cleanup: :environment do |t, args|
        Redcap2omop::RedcapDataDictionary.delete_all
        Redcap2omop::RedcapEventMapDependent.delete_all
        Redcap2omop::RedcapEventMap.delete_all
        Redcap2omop::RedcapEvent.delete_all
        Redcap2omop::RedcapVariableChildMap.delete_all
        Redcap2omop::RedcapVariableChoiceMap.delete_all
        Redcap2omop::RedcapVariableChoice.delete_all
        Redcap2omop::RedcapVariableMap.delete_all
        Redcap2omop::RedcapSourceLink.delete_all
        Redcap2omop::RedcapVariable.delete_all
      end

      desc 'Import data dictionary from CSV'
      task from_csv: :environment do  |t, args|
        raise "project_id has to be provided" if ENV["PROJECT_ID"].blank?

        redcap_project = Redcap2omop::RedcapProject.where(project_id: ENV["PROJECT_ID"].strip).first
        raise "Could not find a project with project_id '#{ENV["PROJECT_ID"]}'" if redcap_project.blank?
        raise "file name required e.g. 'FILE=~/dictionary.csv'" if ENV["FILE"].blank?
        file = ENV['FILE']
        raise "File does not exist: #{file}" unless FileTest.exists?(file)

        import = Redcap2omop::DictionaryServices::CsvImport.new(
          redcap_project: redcap_project,
          csv_file: file,
          csv_file_options: { headers: true, col_sep: ",", return_headers: false,  quote_char: "\""}
        ).run
        if import.success
          puts 'Successfully imported'
        else
          puts 'Error importing: ' + import.message
          puts import.backtrace
        end
      end

      desc 'Import data dictionaries from REDCap'
      task from_redcap: :environment do |t, args|
        Redcap2omop::RedcapProject.not_deleted.api_importable.all.each do |redcap_project|
          import = Redcap2omop::DictionaryServices::RedcapImport.new(redcap_project: redcap_project).run
          if import.success
            puts "Successfully imported #{redcap_project.name} data dictionary"
          else
            puts "Error importing #{redcap_project.name} data dictionary: #{import.message}"
            puts import.backtrace
          end
        end
      end
    end

    desc "Load REDCap records"
    task data: :environment  do |t, args|
      Redcap2omop::RedcapProject.not_deleted.all.each do |redcap_project|
        import = Redcap2omop::DataServices::RedcapImport.new(redcap_project: redcap_project).run
        if import.success
          puts "Successfully imported #{redcap_project.name} data"
        else
          puts "Error importing #{redcap_project.name} data: #{import.message}"
          puts import.backtrace
        end
      end
    end

    desc "REDCap2OMOP"
    task(redcap2omop: :environment) do |t, args|
      Redcap2omop::RedcapProject.not_deleted.all.each do |redcap_project|
        load = Redcap2omop::DataServices::RedcapToOmop.new(redcap_project: redcap_project).run
        if load.success
          puts "Successfully loaded #{redcap_project.name} data into Omop"
        else
          puts "Error loading #{redcap_project.name} data into Omop: #{load.message}"
          puts load.backtrace
        end
      end
    end
  end
end
