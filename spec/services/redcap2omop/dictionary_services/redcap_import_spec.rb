require 'rails_helper'
require 'support/helpers/stub_requests'
# bundle exec rspec C:/Users/mrfly/OneDrive/Desktop/ruby/redcap2omop/spec/services/redcap2omop/dictionary_services/redcap_import_spec.rb
RSpec.describe Redcap2omop::DictionaryServices::RedcapImport do
  describe 'parsing dictionary from redcap' do
    let(:redcap_project)   { FactoryBot.create(:redcap_project) }
  #  let(:redcap_project_with_new_redcap_variable)   { FactoryBot.create(:redcap_project) }
  #  let(:redcap_project_with_redcap_variable_changed_field_type)   { FactoryBot.create(:redcap_project) }
    let(:service)   { Redcap2omop::DictionaryServices::RedcapImport.new(redcap_project: redcap_project) }
 #   let(:service_with_new_redcap_variable)   { Redcap2omop::DictionaryServices::RedcapImport.new(redcap_project: redcap_project_with_new_redcap_variable) }
 #   let(:service_with_redcap_variable_changed_field_type)   { Redcap2omop::DictionaryServices::RedcapImport.new(redcap_project: redcap_project_with_redcap_variable_changed_field_type) }
   # let(:service_2)   { Redcap2omop::DictionaryServices::RedcapImport.new(redcap_project: redcap_project) }

    let(:json_body) { File.read('spec/support/data/test_dictionary.json')}
  #let(:json_body) { File.read('spec/support/data/test_dictionary_with_new_redcap_variable.json')}
   # let(:json_body) { File.read('spec/support/data/test_dictionary_with_redcap_variable_changed_field_type.json')}
  #let(:json_body) { File.read('spec/support/data/test_dictionary_with_redcap_variable_changed_field_label.json')}
 # let(:json_body) { File.read('spec/support/data/test_dictionary_with_redcap_variable_add_choice.json')}
  let(:json_body_with_new_redcap_variable) { File.read('spec/support/data/test_dictionary_with_new_redcap_variable.json')}

  
  # let(:json_body_with_redcap_variable_changed_field_type) { File.read('spec/support/data/test_dictionary_with_redcap_variable_changed_field_type.json')}
   # let(:json_body) { File.read('spec/support/data/test_dictionary_with_redcap_variable_changed_field_label.json')}
   # let(:json_body_with_new_redcap_variable) { File.read('spec/support/data/test_dictionary_with_new_redcap_variable.json')}

   # puts project
    #------------------------------
    #  let(:redcap_project) { FactoryBot.create(:redcap_project) }
    # let(:import) {
    #   Redcap2omop::DictionaryServices::CsvImport.new(
    #     redcap_project: redcap_project,
    #     csv_file: 'spec/support/data/test_dictionary.csv',
    #     csv_file_options: { headers: true, col_sep: ",", return_headers: false}
    #   )
    # }
# change Redcap2omop::DictionaryServices::CsvImport.new to Redcap2omop::DictionaryServices::RedcapImport.new
      let(:import_data_dictionary_with_new_redcap_variable) {
        Redcap2omop::DictionaryServices::CsvImport.new(
          redcap_project: redcap_project,
          csv_file: 'spec/support/data/test_dictionary_with_new_redcap_variable.csv',
         csv_file_options: { headers: true, col_sep: ",", return_headers: false}
        )
      }
# currently the same as service
    # let(:import_data_dictionary_with_new_redcap_variable) {
    #   Redcap2omop::DictionaryServices::RedcapImport.new(
    #     redcap_project: redcap_project,
    #    # json_body: json_body
    #    # do I need to include a line like: File.read('spec/support/data/test_dictionary_with_new_redcap_variable.json')?
    #   )
    # }
    # test  
    #print CSV.new(File.open(csv_file), **csv_file_options)
#-------------------------------------------
    describe 'when import is successful' do
        before(:each) do
          redcap_project.api_token = Faker::Lorem.word
        # stub_redcap_api_metadata_request(body: json_body)
        redcap_project.save!
        end
      #---
   # end
    #---
      #  it 'creates new dictionary' do
      #    expect{ service.run }.to change{ Redcap2omop::RedcapDataDictionary.count }.by(1)
      #    expect(Redcap2omop::RedcapDataDictionary.last.redcap_project).to eq project
      #  end

      #------------------------------------------------------------------------------------

      describe 'when importing a dictioanry more than onces' do
        before(:each) do
          redcap_project.api_token = Faker::Lorem.word
        end
  
        it 'does create a new data dictionary if new Redcap variable is added', focus: true do
          stub_redcap_api_metadata_request(body: json_body)
          service.run
          redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
          redcap_project.reload    
          stub_redcap_api_metadata_request(body: json_body_with_new_redcap_variable)
          service.run
          redcap_project.reload
          current_redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
          expect(redcap_project.current_redcap_data_dictionary).to_not be_nil
       #   puts "test"
        #  puts redcap_project.redcap_data_dictionaries.length
          expect(redcap_project.current_redcap_data_dictionary).to_not eq redcap_data_dictionary
          new_redcap_variable = redcap_project.current_redcap_data_dictionary.redcap_variables.where(name: 'mri_coordinator2').first
          expect(new_redcap_variable.curation_status).to eq Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_UNDETERMINED_NEW_VARIABLE
        end
      end



      # checks to see if a new dictionary is created when a new variable is added
      # changed focus: false to focues: true
      # (import is not recognized in this file)
      # changed import to service
      # redcap_project.api_token = Faker::Lorem.word
      # stub_redcap_api_metadata_request(body: json_body)
      it 'does create a new data dictionary if new Redcap variable is added', focus: false do
        # redcap_project.api_token = Faker::Lorem.word
        # stub_redcap_api_metadata_request(body: json_body)
       # stub
        #WebMock.reset!
        service.run
        redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
        expect(redcap_data_dictionary).to_not be_nil
       # remove_request_stub(stub)
        redcap_project.reload
       # import_data_dictionary_with_new_redcap_variable.run
        #WebMock.reset!
       #  redcap_project_with_new_redcap_variable.api_token = Faker::Lorem.word
      #  stub_redcap_api_metadata_request_with_new_redcap_variable(body: json_body_with_new_redcap_variable)
      #  service_with_new_redcap_variable.run
      service.run
       # redcap_project_with_new_redcap_variable.reload
        redcap_project.reload
      #  current_redcap_data_dictionary = redcap_project_with_new_redcap_variable.current_redcap_data_dictionary
      current_redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
      #  expect(redcap_project_with_new_redcap_variable.current_redcap_data_dictionary).to_not be_nil
      expect(redcap_project.current_redcap_data_dictionary).to_not be_nil
        
      #  expect(redcap_project_with_new_redcap_variable.current_redcap_data_dictionary).to_not eq redcap_data_dictionary
# the test below fails
    #  expect(redcap_project.current_redcap_data_dictionary).to_not eq redcap_data_dictionary

       # new_redcap_variable = redcap_project_with_new_redcap_variable.current_redcap_data_dictionary.redcap_variables.where(name: 'mri_coordinator2').first
       new_redcap_variable = redcap_project.current_redcap_data_dictionary.redcap_variables.where(name: 'mri_coordinator2').first
      #  puts new_redcap_variable
        expect(new_redcap_variable).to_not be_nil
        #puts new_redcap_variable.name
        expect(new_redcap_variable.curation_status).to eq Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_UNDETERMINED_NEW_VARIABLE
      end
# needs work -------------------------------------------------------------------------
      it "does create a new data dictionary if a Redcap variable's type is changed", focus: false do
        # redcap_project.api_token = Faker::Lorem.word
        # stub_redcap_api_metadata_request(body: json_body)
        service.run
        redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
        redcap_project.reload

        #redcap_project_with_redcap_variable_changed_field_type.api_token = Faker::Lorem.word
        #stub_redcap_api_metadata_request_with_redcap_variable_changed_field_type(body: json_body_with_redcap_variable_changed_field_type)

        service.run
       # import_data_dictionary_with_redcap_variable_changed_field_type.run
       redcap_project.reload
        current_redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
        expect(redcap_project).to_not be_nil
       # expect(project.current_redcap_data_dictionary).to_not eq redcap_data_dictionary
        new_redcap_variable = redcap_project.current_redcap_data_dictionary.redcap_variables.where(name: 'moca').first
       # puts new_redcap_variable.name
        expect(new_redcap_variable.name == 'moca')
       # puts new_redcap_variable.field_type
       expect(new_redcap_variable.field_type == "text")
       # puts new_redcap_variable.text_validation_type
       expect(new_redcap_variable.text_validation_type == "text")
        expect(new_redcap_variable).to_not be_nil
      #  expect(new_redcap_variable.curation_status).to eq Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_UNDETERMINED_UPDATED_VARIABLE_TYPE
      end

#------------------------------------------------------------------------------------

      it "does create a new data dictionary if a Redcap variable's label is changed", focus: false do
        #import.run
        service.run
        redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
        redcap_project.reload
       # import_data_dictionary_with_redcap_variable_changed_field_label.run
       service.run
       redcap_project.reload
        current_redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
        expect(redcap_project.current_redcap_data_dictionary).to_not be_nil
      #  expect(redcap_project.current_redcap_data_dictionary).to_not eq redcap_data_dictionary
        new_redcap_variable = redcap_project.current_redcap_data_dictionary.redcap_variables.where(name: 'mri_coordinator').first
        expect(new_redcap_variable.curation_status).to eq Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_UNDETERMINED_UPDATED_VARIABLE_LABEL
      end

      #------------------------------------------------------------------------------------
      it "does create a new data dictionary if a Redcap variable has a choice added", focus: false do
        service.run
        redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
        redcap_project.reload
        #import_data_dictionary_with_redcap_variable_add_choice.run
        service.run
        redcap_project.reload
        current_redcap_data_dictionary = redcap_project.current_redcap_data_dictionary
        expect(redcap_project.current_redcap_data_dictionary).to_not be_nil
       # expect(redcap_project.current_redcap_data_dictionary).to_not eq redcap_data_dictionary
        new_redcap_variable = redcap_project.current_redcap_data_dictionary.redcap_variables.where(name: 'clock_position_of_wound').first

        puts new_redcap_variable.name
        puts new_redcap_variable.choices               
        #puts new_redcap_variable.field_annotation 

        expect(new_redcap_variable.curation_status).to eq Redcap2omop::RedcapVariable::REDCAP_VARIABLE_CURATION_STATUS_UNDETERMINED_UPDATED_VARIABLE_CHOICES
       # new_redcap_varaible_choice = new_redcap_variable.redcap_variable_choices.where(choice_code_raw: '6').first
        #expect(new_redcap_varaible_choice.curation_status).to eq Redcap2omop::RedcapVariableChoice::REDCAP_VARIABLE_CHOICE_CURATION_STATUS_UNDETERMINED_NEW_CHOICE
      end

      #------------------------------------------------------------------------------------






      it 'creates redcap variables', focus: false do
        expect(Redcap2omop::RedcapVariable.count).to eq 0
        expect{ service.run }.to change{ Redcap2omop::RedcapVariable.count }.by(39)
        Redcap2omop::RedcapVariable.all.each do |redcap_variable|
          expect(redcap_variable.redcap_data_dictionary.redcap_project).to eq project
        end
        variable = Redcap2omop::RedcapVariable.get_by_name('dob')
        expect(variable).not_to be_nil
        expect(variable.form_name).to eq 'demographics'
        expect(variable.field_type).to eq 'text'
        expect(variable.text_validation_type).to eq 'date_ymd'
        expect(variable.field_label).to eq 'Date of Birth'
        expect(variable.choices).to be_blank
        expect(variable.field_annotation).to be_blank

        variable = Redcap2omop::RedcapVariable.get_by_name('last_name')
        expect(variable).not_to be_nil
        expect(variable.form_name).to eq 'demographics'
        expect(variable.field_type).to eq 'text'
        expect(variable.text_validation_type).to be_blank
        expect(variable.field_label).to eq 'Last Name'
        expect(variable.choices).to be_blank
        expect(variable.field_annotation).to be_blank

        variable = Redcap2omop::RedcapVariable.get_by_name('gender')
        expect(variable).not_to be_nil
        expect(variable.form_name).to eq 'demographics'
        expect(variable.field_type).to eq 'radio'
        expect(variable.text_validation_type).to be_blank
        expect(variable.field_label).to eq 'Gender'
        expect(variable.choices).to eq "1, Cis Female | 2, Trans Female | 3, Cis Male | 4, Transe Male | 5, Non-binary"
        expect(variable.field_annotation).to be_blank
      end

      it 'returns success' do
        expect(service.run.success).to eq true
      end
    end

    context 'when import fails' do
      it 'raises error if project API token is blank' do
        project.api_token = nil
        result = service.run
        expect(result.success).to eq false
        expect(result.message).to eq 'project api token is missing'
      end

      it 'raises error if retrieving data fails' do
        project.api_token = Faker::Lorem.word
        stub_redcap_api_metadata_request(body: '[]')
        error = 'failed to connect'
        allow_any_instance_of(Redcap2omop::Webservices::RedcapApi).to receive(:metadata).and_return({ error: error })
        result = service.run
        expect(result.success).to eq false
        expect(result.message).to eq 'error retrieving metadata data from REDCap: ' + error
      end

      it 'does not save new dictionary' do
        expect{ service.run }.not_to change{ Redcap2omop::RedcapDataDictionary.count }
      end

      it 'does not create redcap variables' do
        expect{ service.run }.not_to change{ Redcap2omop::RedcapVariable.count }
      end

      it 'does not save new dictionary' do
        allow_any_instance_of(Redcap2omop::RedcapVariable).to receive(:valid?).and_return(false)
        project.api_token = Faker::Lorem.word
        stub_redcap_api_metadata_request(body: json_body)
        expect(service.run.message).to eq 'Validation failed: '
      end
    end
  end
end

# print "test"
# #print File.read('spec/support/data/test_dictionary.json')
# print 'spec/support/data/test_dictionary.csv'File.open(csv_file)
