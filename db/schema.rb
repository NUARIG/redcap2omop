# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_01_11_192158) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "attribute_definition", id: false, force: :cascade do |t|
    t.integer "attribute_definition_id", null: false
    t.string "attribute_name", limit: 255, null: false
    t.text "attribute_description"
    t.integer "attribute_type_concept_id", null: false
    t.text "attribute_syntax"
  end

  create_table "care_site", id: false, force: :cascade do |t|
    t.integer "care_site_id", null: false
    t.string "care_site_name", limit: 255
    t.integer "place_of_service_concept_id"
    t.integer "location_id"
    t.string "care_site_source_value", limit: 50
    t.string "place_of_service_source_value", limit: 50
  end

  create_table "cdm_source", id: false, force: :cascade do |t|
    t.string "cdm_source_name", limit: 255, null: false
    t.string "cdm_source_abbreviation", limit: 25
    t.string "cdm_holder", limit: 255
    t.text "source_description"
    t.string "source_documentation_reference", limit: 255
    t.string "cdm_etl_reference", limit: 255
    t.date "source_release_date"
    t.date "cdm_release_date"
    t.string "cdm_version", limit: 10
    t.string "vocabulary_version", limit: 20
  end

  create_table "cohort", id: false, force: :cascade do |t|
    t.integer "cohort_definition_id", null: false
    t.integer "subject_id", null: false
    t.date "cohort_start_date", null: false
    t.date "cohort_end_date", null: false
  end

  create_table "cohort_attribute", id: false, force: :cascade do |t|
    t.integer "cohort_definition_id", null: false
    t.integer "subject_id", null: false
    t.date "cohort_start_date", null: false
    t.date "cohort_end_date", null: false
    t.integer "attribute_definition_id", null: false
    t.decimal "value_as_number"
    t.integer "value_as_concept_id"
  end

  create_table "cohort_definition", id: false, force: :cascade do |t|
    t.integer "cohort_definition_id", null: false
    t.string "cohort_definition_name", limit: 255, null: false
    t.text "cohort_definition_description"
    t.integer "definition_type_concept_id", null: false
    t.text "cohort_definition_syntax"
    t.integer "subject_concept_id", null: false
    t.date "cohort_initiation_date"
  end

  create_table "concept", id: false, force: :cascade do |t|
    t.integer "concept_id", null: false
    t.string "concept_name", limit: 255, null: false
    t.string "domain_id", limit: 20, null: false
    t.string "vocabulary_id", limit: 20, null: false
    t.string "concept_class_id", limit: 20, null: false
    t.string "standard_concept", limit: 1
    t.string "concept_code", limit: 50, null: false
    t.date "valid_start_date", null: false
    t.date "valid_end_date", null: false
    t.string "invalid_reason", limit: 1
  end

  create_table "concept_ancestor", id: false, force: :cascade do |t|
    t.integer "ancestor_concept_id", null: false
    t.integer "descendant_concept_id", null: false
    t.integer "min_levels_of_separation", null: false
    t.integer "max_levels_of_separation", null: false
  end

  create_table "concept_class", id: false, force: :cascade do |t|
    t.string "concept_class_id", limit: 20, null: false
    t.string "concept_class_name", limit: 255, null: false
    t.integer "concept_class_concept_id", null: false
  end

  create_table "concept_relationship", id: false, force: :cascade do |t|
    t.integer "concept_id_1", null: false
    t.integer "concept_id_2", null: false
    t.string "relationship_id", limit: 20, null: false
    t.date "valid_start_date", null: false
    t.date "valid_end_date", null: false
    t.string "invalid_reason", limit: 1
  end

  create_table "concept_synonym", id: false, force: :cascade do |t|
    t.integer "concept_id", null: false
    t.string "concept_synonym_name", limit: 1000, null: false
    t.integer "language_concept_id", null: false
  end

  create_table "condition_era", id: false, force: :cascade do |t|
    t.integer "condition_era_id", null: false
    t.integer "person_id", null: false
    t.integer "condition_concept_id", null: false
    t.date "condition_era_start_date", null: false
    t.date "condition_era_end_date", null: false
    t.integer "condition_occurrence_count"
  end

  create_table "condition_occurrence", id: false, force: :cascade do |t|
    t.integer "condition_occurrence_id", null: false
    t.integer "person_id", null: false
    t.integer "condition_concept_id", null: false
    t.date "condition_start_date", null: false
    t.datetime "condition_start_datetime"
    t.date "condition_end_date"
    t.datetime "condition_end_datetime"
    t.integer "condition_type_concept_id", null: false
    t.string "stop_reason", limit: 20
    t.integer "provider_id"
    t.integer "visit_occurrence_id"
    t.integer "visit_detail_id"
    t.string "condition_source_value", limit: 50
    t.integer "condition_source_concept_id"
    t.string "condition_status_source_value", limit: 50
    t.integer "condition_status_concept_id"
  end

  create_table "cost", id: false, force: :cascade do |t|
    t.integer "cost_id", null: false
    t.integer "cost_event_id", null: false
    t.string "cost_domain_id", limit: 20, null: false
    t.integer "cost_type_concept_id", null: false
    t.integer "currency_concept_id"
    t.decimal "total_charge"
    t.decimal "total_cost"
    t.decimal "total_paid"
    t.decimal "paid_by_payer"
    t.decimal "paid_by_patient"
    t.decimal "paid_patient_copay"
    t.decimal "paid_patient_coinsurance"
    t.decimal "paid_patient_deductible"
    t.decimal "paid_by_primary"
    t.decimal "paid_ingredient_cost"
    t.decimal "paid_dispensing_fee"
    t.integer "payer_plan_period_id"
    t.decimal "amount_allowed"
    t.integer "revenue_code_concept_id"
    t.string "reveue_code_source_value", limit: 50
    t.integer "drg_concept_id"
    t.string "drg_source_value", limit: 3
  end

  create_table "death", id: false, force: :cascade do |t|
    t.integer "person_id", null: false
    t.date "death_date", null: false
    t.datetime "death_datetime"
    t.integer "death_type_concept_id", null: false
    t.integer "cause_concept_id"
    t.string "cause_source_value", limit: 50
    t.integer "cause_source_concept_id"
  end

  create_table "device_exposure", id: false, force: :cascade do |t|
    t.integer "device_exposure_id", null: false
    t.integer "person_id", null: false
    t.integer "device_concept_id", null: false
    t.date "device_exposure_start_date", null: false
    t.datetime "device_exposure_start_datetime"
    t.date "device_exposure_end_date"
    t.datetime "device_exposure_end_datetime"
    t.integer "device_type_concept_id", null: false
    t.string "unique_device_id", limit: 50
    t.integer "quantity"
    t.integer "provider_id"
    t.integer "visit_occurrence_id"
    t.integer "visit_detail_id"
    t.string "device_source_value", limit: 100
    t.integer "device_source_concept_id"
  end

  create_table "domain", id: false, force: :cascade do |t|
    t.string "domain_id", limit: 20, null: false
    t.string "domain_name", limit: 255, null: false
    t.integer "domain_concept_id", null: false
  end

  create_table "dose_era", id: false, force: :cascade do |t|
    t.integer "dose_era_id", null: false
    t.integer "person_id", null: false
    t.integer "drug_concept_id", null: false
    t.integer "unit_concept_id", null: false
    t.decimal "dose_value", null: false
    t.date "dose_era_start_date", null: false
    t.date "dose_era_end_date", null: false
  end

  create_table "drug_era", id: false, force: :cascade do |t|
    t.integer "drug_era_id", null: false
    t.integer "person_id", null: false
    t.integer "drug_concept_id", null: false
    t.date "drug_era_start_date", null: false
    t.date "drug_era_end_date", null: false
    t.integer "drug_exposure_count"
    t.integer "gap_days"
  end

  create_table "drug_exposure", id: false, force: :cascade do |t|
    t.integer "drug_exposure_id", null: false
    t.integer "person_id", null: false
    t.integer "drug_concept_id", null: false
    t.date "drug_exposure_start_date", null: false
    t.datetime "drug_exposure_start_datetime"
    t.date "drug_exposure_end_date", null: false
    t.datetime "drug_exposure_end_datetime"
    t.date "verbatim_end_date"
    t.integer "drug_type_concept_id", null: false
    t.string "stop_reason", limit: 20
    t.integer "refills"
    t.decimal "quantity"
    t.integer "days_supply"
    t.text "sig"
    t.integer "route_concept_id"
    t.string "lot_number", limit: 50
    t.integer "provider_id"
    t.integer "visit_occurrence_id"
    t.integer "visit_detail_id"
    t.string "drug_source_value", limit: 50
    t.integer "drug_source_concept_id"
    t.string "route_source_value", limit: 50
    t.string "dose_unit_source_value", limit: 50
  end

  create_table "drug_strength", id: false, force: :cascade do |t|
    t.integer "drug_concept_id", null: false
    t.integer "ingredient_concept_id", null: false
    t.decimal "amount_value"
    t.integer "amount_unit_concept_id"
    t.decimal "numerator_value"
    t.integer "numerator_unit_concept_id"
    t.decimal "denominator_value"
    t.integer "denominator_unit_concept_id"
    t.integer "box_size"
    t.date "valid_start_date", null: false
    t.date "valid_end_date", null: false
    t.string "invalid_reason", limit: 1
  end

  create_table "fact_relationship", id: false, force: :cascade do |t|
    t.integer "domain_concept_id_1", null: false
    t.integer "fact_id_1", null: false
    t.integer "domain_concept_id_2", null: false
    t.integer "fact_id_2", null: false
    t.integer "relationship_concept_id", null: false
  end

  create_table "location", id: false, force: :cascade do |t|
    t.integer "location_id", null: false
    t.string "address_1", limit: 50
    t.string "address_2", limit: 50
    t.string "city", limit: 50
    t.string "state", limit: 2
    t.string "zip", limit: 9
    t.string "county", limit: 20
    t.string "location_source_value", limit: 50
  end

  create_table "measurement", id: false, force: :cascade do |t|
    t.integer "measurement_id", null: false
    t.integer "person_id", null: false
    t.integer "measurement_concept_id", null: false
    t.date "measurement_date", null: false
    t.datetime "measurement_datetime"
    t.string "measurement_time", limit: 10
    t.integer "measurement_type_concept_id", null: false
    t.integer "operator_concept_id"
    t.decimal "value_as_number"
    t.integer "value_as_concept_id"
    t.integer "unit_concept_id"
    t.decimal "range_low"
    t.decimal "range_high"
    t.integer "provider_id"
    t.integer "visit_occurrence_id"
    t.integer "visit_detail_id"
    t.string "measurement_source_value", limit: 50
    t.integer "measurement_source_concept_id"
    t.string "unit_source_value", limit: 50
    t.string "value_source_value", limit: 50
  end

  create_table "metadata", id: false, force: :cascade do |t|
    t.integer "metadata_concept_id", null: false
    t.integer "metadata_type_concept_id", null: false
    t.string "name", limit: 250, null: false
    t.text "value_as_string"
    t.integer "value_as_concept_id"
    t.date "metadata_date"
    t.datetime "metadata_datetime"
  end

  create_table "note", id: false, force: :cascade do |t|
    t.integer "note_id", null: false
    t.integer "person_id", null: false
    t.date "note_date", null: false
    t.datetime "note_datetime"
    t.integer "note_type_concept_id", null: false
    t.integer "note_class_concept_id", null: false
    t.string "note_title", limit: 250
    t.text "note_text"
    t.integer "encoding_concept_id", null: false
    t.integer "language_concept_id", null: false
    t.integer "provider_id"
    t.integer "visit_occurrence_id"
    t.integer "visit_detail_id"
    t.string "note_source_value", limit: 50
  end

  create_table "note_nlp", id: false, force: :cascade do |t|
    t.integer "note_nlp_id", null: false
    t.integer "note_id", null: false
    t.integer "section_concept_id"
    t.string "snippet", limit: 250
    t.string "offset", limit: 250
    t.string "lexical_variant", limit: 250, null: false
    t.integer "note_nlp_concept_id"
    t.integer "note_nlp_source_concept_id"
    t.string "nlp_system", limit: 250
    t.date "nlp_date", null: false
    t.datetime "nlp_datetime"
    t.string "term_exists", limit: 1
    t.string "term_temporal", limit: 50
    t.string "term_modifiers", limit: 2000
  end

  create_table "observation", id: false, force: :cascade do |t|
    t.integer "observation_id", null: false
    t.integer "person_id", null: false
    t.integer "observation_concept_id", null: false
    t.date "observation_date", null: false
    t.datetime "observation_datetime"
    t.integer "observation_type_concept_id", null: false
    t.decimal "value_as_number"
    t.string "value_as_string", limit: 60
    t.integer "value_as_concept_id"
    t.integer "qualifier_concept_id"
    t.integer "unit_concept_id"
    t.integer "provider_id"
    t.integer "visit_occurrence_id"
    t.integer "visit_detail_id"
    t.string "observation_source_value", limit: 50
    t.integer "observation_source_concept_id"
    t.string "unit_source_value", limit: 50
    t.string "qualifier_source_value", limit: 50
    t.string "value_source_value", limit: 50
  end

  create_table "observation_period", id: false, force: :cascade do |t|
    t.integer "observation_period_id", null: false
    t.integer "person_id", null: false
    t.date "observation_period_start_date", null: false
    t.date "observation_period_end_date", null: false
    t.integer "period_type_concept_id", null: false
  end

  create_table "omop_columns", force: :cascade do |t|
    t.integer "omop_table_id", null: false
    t.string "name", null: false
    t.string "data_type", null: false
    t.string "map_type", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
  end

  create_table "omop_tables", force: :cascade do |t|
    t.string "domain"
    t.string "name", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
  end

  create_table "payer_plan_period", id: false, force: :cascade do |t|
    t.integer "payer_plan_period_id", null: false
    t.integer "person_id", null: false
    t.date "payer_plan_period_start_date", null: false
    t.date "payer_plan_period_end_date", null: false
    t.integer "payer_concept_id"
    t.string "payer_source_value", limit: 50
    t.integer "payer_source_concept_id"
    t.integer "plan_concept_id"
    t.string "plan_source_value", limit: 50
    t.integer "plan_source_concept_id"
    t.integer "sponsor_concept_id"
    t.string "sponsor_source_value", limit: 50
    t.integer "sponsor_source_concept_id"
    t.string "family_source_value", limit: 50
    t.integer "stop_reason_concept_id"
    t.string "stop_reason_source_value", limit: 50
    t.integer "stop_reason_source_concept_id"
  end

  create_table "person", id: false, force: :cascade do |t|
    t.integer "person_id", null: false
    t.integer "gender_concept_id", null: false
    t.integer "year_of_birth", null: false
    t.integer "month_of_birth"
    t.integer "day_of_birth"
    t.datetime "birth_datetime"
    t.integer "race_concept_id", null: false
    t.integer "ethnicity_concept_id", null: false
    t.integer "location_id"
    t.integer "provider_id"
    t.integer "care_site_id"
    t.string "person_source_value", limit: 50
    t.string "gender_source_value", limit: 50
    t.integer "gender_source_concept_id"
    t.string "race_source_value", limit: 50
    t.integer "race_source_concept_id"
    t.string "ethnicity_source_value", limit: 50
    t.integer "ethnicity_source_concept_id"
  end

  create_table "procedure_occurrence", id: false, force: :cascade do |t|
    t.integer "procedure_occurrence_id", null: false
    t.integer "person_id", null: false
    t.integer "procedure_concept_id", null: false
    t.date "procedure_date", null: false
    t.datetime "procedure_datetime"
    t.integer "procedure_type_concept_id", null: false
    t.integer "modifier_concept_id"
    t.integer "quantity"
    t.integer "provider_id"
    t.integer "visit_occurrence_id"
    t.integer "visit_detail_id"
    t.string "procedure_source_value", limit: 50
    t.integer "procedure_source_concept_id"
    t.string "modifier_source_value", limit: 50
  end

  create_table "provider", id: false, force: :cascade do |t|
    t.integer "provider_id", null: false
    t.string "provider_name", limit: 255
    t.string "npi", limit: 20
    t.string "dea", limit: 20
    t.integer "specialty_concept_id"
    t.integer "care_site_id"
    t.integer "year_of_birth"
    t.integer "gender_concept_id"
    t.string "provider_source_value", limit: 50
    t.string "specialty_source_value", limit: 50
    t.integer "specialty_source_concept_id"
    t.string "gender_source_value", limit: 50
    t.integer "gender_source_concept_id"
  end

  create_table "redcap_data_dictionaries", force: :cascade do |t|
    t.integer "redcap_project_id", null: false
    t.integer "version", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
  end

  create_table "redcap_event_map_dependents", force: :cascade do |t|
    t.integer "redcap_variable_id", null: false
    t.integer "redcap_event_id", null: false
    t.integer "concept_id"
    t.integer "omop_column_id"
    t.datetime "deleted_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "redcap_event_maps", force: :cascade do |t|
    t.integer "redcap_event_id", null: false
    t.integer "concept_id"
    t.datetime "deleted_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "redcap_events", force: :cascade do |t|
    t.integer "redcap_data_dictionary_id", null: false
    t.string "event_name", null: false
    t.integer "arm_num", null: false
    t.integer "day_offset", null: false
    t.integer "offset_min", null: false
    t.integer "offset_max", null: false
    t.string "unique_event_name", null: false
    t.string "custom_event_label"
    t.datetime "deleted_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "redcap_projects", force: :cascade do |t|
    t.integer "project_id", null: false
    t.string "name", null: false
    t.string "api_token"
    t.string "export_table_name", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
    t.boolean "route_to_observation"
    t.boolean "insert_person"
    t.boolean "api_import"
    t.boolean "complete_instrument", default: false, null: false
  end

  create_table "redcap_source_links", force: :cascade do |t|
    t.string "redcap_source_type"
    t.integer "redcap_source_id"
    t.string "redcap_sourced_type"
    t.integer "redcap_sourced_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "redcap_variable_child_maps", force: :cascade do |t|
    t.integer "redcap_variable_id", null: false
    t.integer "parentable_id", null: false
    t.string "parentable_type", null: false
    t.integer "concept_id"
    t.integer "omop_column_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
  end

  create_table "redcap_variable_choice_maps", force: :cascade do |t|
    t.integer "redcap_variable_choice_id", null: false
    t.integer "concept_id"
    t.integer "omop_column_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
  end

  create_table "redcap_variable_choices", force: :cascade do |t|
    t.integer "redcap_variable_id", null: false
    t.string "choice_code_raw", null: false
    t.string "choice_code_concept_code"
    t.string "choice_description", null: false
    t.string "vocabulary_id_raw"
    t.string "vocabulary_id"
    t.string "map_choice"
    t.string "choice_code_value_as_concept_code"
    t.string "value_as_vocabualry_id"
    t.decimal "ordinal_position", null: false
    t.boolean "curated", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
  end

  create_table "redcap_variable_maps", force: :cascade do |t|
    t.integer "redcap_variable_id", null: false
    t.integer "concept_id"
    t.integer "omop_column_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
  end

  create_table "redcap_variables", force: :cascade do |t|
    t.integer "redcap_data_dictionary_id", null: false
    t.string "name", null: false
    t.string "form_name", null: false
    t.string "field_type", null: false
    t.string "field_type_normalized", null: false
    t.text "field_label", null: false
    t.text "choices"
    t.string "text_validation_type"
    t.string "field_annotation"
    t.decimal "ordinal_position"
    t.boolean "curated"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
    t.string "field_type_curated"
    t.string "curation_status"
  end

  create_table "relationship", id: false, force: :cascade do |t|
    t.string "relationship_id", limit: 20, null: false
    t.string "relationship_name", limit: 255, null: false
    t.string "is_hierarchical", limit: 1, null: false
    t.string "defines_ancestry", limit: 1, null: false
    t.string "reverse_relationship_id", limit: 20, null: false
    t.integer "relationship_concept_id", null: false
  end

  create_table "source_to_concept_map", id: false, force: :cascade do |t|
    t.string "source_code", limit: 50, null: false
    t.integer "source_concept_id", null: false
    t.string "source_vocabulary_id", limit: 20, null: false
    t.string "source_code_description", limit: 255
    t.integer "target_concept_id", null: false
    t.string "target_vocabulary_id", limit: 20, null: false
    t.date "valid_start_date", null: false
    t.date "valid_end_date", null: false
    t.string "invalid_reason", limit: 1
  end

  create_table "specimen", id: false, force: :cascade do |t|
    t.integer "specimen_id", null: false
    t.integer "person_id", null: false
    t.integer "specimen_concept_id", null: false
    t.integer "specimen_type_concept_id", null: false
    t.date "specimen_date", null: false
    t.datetime "specimen_datetime"
    t.decimal "quantity"
    t.integer "unit_concept_id"
    t.integer "anatomic_site_concept_id"
    t.integer "disease_status_concept_id"
    t.string "specimen_source_id", limit: 50
    t.string "specimen_source_value", limit: 50
    t.string "unit_source_value", limit: 50
    t.string "anatomic_site_source_value", limit: 50
    t.string "disease_status_source_value", limit: 50
  end

  create_table "visit_detail", id: false, force: :cascade do |t|
    t.integer "visit_detail_id", null: false
    t.integer "person_id", null: false
    t.integer "visit_detail_concept_id", null: false
    t.date "visit_detail_start_date", null: false
    t.datetime "visit_detail_start_datetime"
    t.date "visit_detail_end_date", null: false
    t.datetime "visit_detail_end_datetime"
    t.integer "visit_detail_type_concept_id", null: false
    t.integer "provider_id"
    t.integer "care_site_id"
    t.integer "admitting_source_concept_id"
    t.integer "discharge_to_concept_id"
    t.integer "preceding_visit_detail_id"
    t.string "visit_detail_source_value", limit: 50
    t.integer "visit_detail_source_concept_id"
    t.string "admitting_source_value", limit: 50
    t.string "discharge_to_source_value", limit: 50
    t.integer "visit_detail_parent_id"
    t.integer "visit_occurrence_id", null: false
  end

  create_table "visit_occurrence", id: false, force: :cascade do |t|
    t.integer "visit_occurrence_id", null: false
    t.integer "person_id", null: false
    t.integer "visit_concept_id", null: false
    t.date "visit_start_date", null: false
    t.datetime "visit_start_datetime"
    t.date "visit_end_date", null: false
    t.datetime "visit_end_datetime"
    t.integer "visit_type_concept_id", null: false
    t.integer "provider_id"
    t.integer "care_site_id"
    t.string "visit_source_value", limit: 50
    t.integer "visit_source_concept_id"
    t.integer "admitting_source_concept_id"
    t.string "admitting_source_value", limit: 50
    t.integer "discharge_to_concept_id"
    t.string "discharge_to_source_value", limit: 50
    t.integer "preceding_visit_occurrence_id"
  end

  create_table "vocabulary", id: false, force: :cascade do |t|
    t.string "vocabulary_id", limit: 20, null: false
    t.string "vocabulary_name", limit: 255, null: false
    t.string "vocabulary_reference", limit: 255, null: false
    t.string "vocabulary_version", limit: 255
    t.integer "vocabulary_concept_id", null: false
  end

end
