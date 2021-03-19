require 'highline/import'
# bundle exec rake data:truncate_omop_clinical_data_tables
#
#
# CCC19 workflow
# bundle exec rake setup:ccc19:project
# bundle exec rake ingest:data_dictionary:cleanup
# bundle exec rake ingest:data_dictionary:from_csv
# bundle exec rake setup:omop_tables

# bundle exec rake setup:ccc19:maps
# bundle exec rake ingest:data
# bundle exec rake ingest:redcap2omop
#
# Neurofiles workflow
# bundle exec rake setup:neurofiles:projects
# bundle exec rake setup:neurofiles:project_sandbox
# bundle exec rake ingest:data_dictionary:cleanup
# bundle exec rake ingest:data_dictionary:from_redcap
# bundle exec rake setup:omop_tables

# bundle exec rake setup:ccc19:insert_people

# bundle exec rake setup:neurofiles:maps
# bundle exec rake setup:neurofiles:maps_sandbox
# bundle exec rake ingest:data
# bundle exec rake ingest:redcap2omop

namespace :ingest do
  namespace :data_dictionary do
    desc 'Cleanup data dictionaries'
    task cleanup: :environment do |t, args|
      RedcapDataDictionary.delete_all
      RedcapEventMapDependent.delete_all
      RedcapEventMap.delete_all
      RedcapEvent.delete_all
      RedcapVariableChildMap.delete_all
      RedcapVariableChoiceMap.delete_all
      RedcapVariableChoice.delete_all
      RedcapVariableMap.delete_all
      RedcapVariable.delete_all
    end

    desc 'Import data dictionary from CSV'
    task from_csv: :environment do  |t, args|

      import_folder = File.join(Rails.root, 'lib', 'setup', 'data', 'data_dictionaries')
      file_list = Dir.glob(File.join(import_folder,'*.csv')).sort
      fail "no dictionary files (*.csv) found in #{import_folder}" if file_list.empty?

      file_list.each_with_index{|f,i| puts "#{i+1}:#{File.basename(f)}"}
      file_selected_index = ask('Which file? ', Integer){|q| q.above = 0; q.below = file_list.size+1}

      projects =  RedcapProject.not_deleted.csv_importable.pluck(:project_id, :name)
      projects.each{|p| puts "#{p[0]}:#{p[1]}"}

      project_id = ask('Which project? ', Integer){|q| q.in = projects.map(&:first)}

      # dictionary = DictionaryServices::Parsers.load_dictionary(file_list[file_selected_index.to_i-1], study_id == 0 ? nil : study_id)
      # DictionaryServices::Parsers.create_fields(dictionary)

      import = DictionaryServices::CsvImport.new(
        redcap_project: RedcapProject.where(project_id: project_id).first,
        csv_file: file_list[file_selected_index.to_i-1],
        csv_file_options: { headers: true, col_sep: ",", return_headers: false,  quote_char: "\""}
      ).run
      if import.success
        puts 'Successfully imported'
      else
        puts import.message
        # puts 'Error importing: ' + import.message
        puts import.backtrace
      end
    end

    desc 'Import data dictionaries from REDCap'
    task from_redcap: :environment do |t, args|
      RedcapProject.not_deleted.api_importable.all.each do |redcap_project|
        import = DictionaryServices::RedcapImport.new(redcap_project: redcap_project).run
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
    RedcapProject.not_deleted.all.each do |redcap_project|
      import = DataServices::RedcapImport.new(redcap_project: redcap_project).run
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
    RedcapProject.not_deleted.all.each do |redcap_project|
      load = DataServices::RedcapToOmop.new(redcap_project: redcap_project).run
      if load.success
        puts "Successfully loaded #{redcap_project.name} data into Omop"
      else
        puts "Error loading #{redcap_project.name} data into Omop: #{load.message}"
        puts load.backtrace
      end
    end
  end
end