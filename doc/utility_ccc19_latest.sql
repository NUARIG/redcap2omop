--latest skipped
SELECT  rdd.version
      , rv.form_name
      , rv.name                   AS variable_name
      , rv.field_label            AS varaible_description
      , rv.field_type_normalized  AS field_type
      , rv.text_validation_type
      , rv.curation_status
      , rrvm.map_type             AS variable_map_type
      , rot.name                  AS variable_mapped_omop_table
      , roc.name                  AS variable_mapped_omop_column
      , c1.domain_id              AS variable_map_concept_domain_id
      , c1.vocabulary_id          AS variable_map_concept_vocabulary_id
      , c1.concept_name           AS variable_map_concept_name
      , c1.concept_code           AS variable_map_concept_code
      , c1.concept_id             AS variable_map_concept_id
      , c1.standard_concept       AS variable_map_concept_standard_concept
      , rvc.choice_code_raw       AS variable_choice_code
      , rvc.choice_description    AS variable_choice_description
	    , rvc.curation_status       AS variable_choice_curation_status
      , rvcm.map_type             AS variable_choice_map_type
      , c2.domain_id              AS variable_choice_map_concept_domain_id
      , c2.vocabulary_id          AS variable_choice_map_concept_vocabulary_id
      , c2.concept_name           AS variable_choice_map_concept_name
      , c2.concept_code           AS variable_choice_map_concept_code
      , c2.concept_id             AS variable_choice_map_concept_id
      , c2.standard_concept       AS variable_choice_map_concept_standard_concept
FROM redcap2omop_redcap_variables rv  LEFT JOIN redcap2omop_redcap_variable_maps rrvm         ON rrvm.redcap_variable_id       = rv.id
                                      LEFT JOIN redcap2omop_omop_columns roc                  ON rrvm.omop_column_id           = roc.id
                                      LEFT JOIN redcap2omop_omop_tables rot                   ON roc.omop_table_id             = rot.id
                                      LEFT JOIN concept c1                                    ON rrvm.concept_id               = c1.concept_id
                                      LEFT JOIN redcap2omop_redcap_variable_choices rvc       ON rv.id                         = rvc.redcap_variable_id
                                      LEFT JOIN redcap2omop_redcap_variable_choice_maps rvcm  ON rvc.id                        = rvcm.redcap_variable_choice_id
                                      LEFT JOIN concept c2                                    ON rvcm.concept_id               = c2.concept_id
                                      JOIN redcap2omop_redcap_data_dictionaries rdd           ON rv.redcap_data_dictionary_id  = rdd.id
                                      JOIN redcap2omop_redcap_projects rp                     ON rdd.redcap_project_id         = rp.id
WHERE rp.name = 'CCC19'
AND rdd.version = 2
AND
(
  rv.curation_status = 'skipped'
  OR
  rvc.curation_status  = 'skipped'
)
ORDER BY rv.id, rvc.id


--latest all
SELECT  rdd.version
      , rv.form_name
      , rv.name                   AS variable_name
      , rv.field_label            AS varaible_description
      , rv.field_type_normalized  AS field_type
      , rv.text_validation_type
      , rv.curation_status
      , rrvm.map_type             AS variable_map_type
      , rot.name                  AS variable_mapped_omop_table
      , roc.name                  AS variable_mapped_omop_column
      , c1.domain_id              AS variable_map_concept_domain_id
      , c1.vocabulary_id          AS variable_map_concept_vocabulary_id
      , c1.concept_name           AS variable_map_concept_name
      , c1.concept_code           AS variable_map_concept_code
      , c1.concept_id             AS variable_map_concept_id
      , c1.standard_concept       AS variable_map_concept_standard_concept
      , rvc.choice_code_raw       AS variable_choice_code
      , rvc.choice_description    AS variable_choice_description
	    , rvc.curation_status       AS variable_choice_curation_status
      , rvcm.map_type             AS variable_choice_map_type
      , c2.domain_id              AS variable_choice_map_concept_domain_id
      , c2.vocabulary_id          AS variable_choice_map_concept_vocabulary_id
      , c2.concept_name           AS variable_choice_map_concept_name
      , c2.concept_code           AS variable_choice_map_concept_code
      , c2.concept_id             AS variable_choice_map_concept_id
      , c2.standard_concept       AS variable_choice_map_concept_standard_concept
FROM redcap2omop_redcap_variables rv  LEFT JOIN redcap2omop_redcap_variable_maps rrvm         ON rrvm.redcap_variable_id       = rv.id
                                      LEFT JOIN redcap2omop_omop_columns roc                  ON rrvm.omop_column_id           = roc.id
                                      LEFT JOIN redcap2omop_omop_tables rot                   ON roc.omop_table_id             = rot.id
                                      LEFT JOIN concept c1                                    ON rrvm.concept_id               = c1.concept_id
                                      LEFT JOIN redcap2omop_redcap_variable_choices rvc       ON rv.id                         = rvc.redcap_variable_id
                                      LEFT JOIN redcap2omop_redcap_variable_choice_maps rvcm  ON rvc.id                        = rvcm.redcap_variable_choice_id
                                      LEFT JOIN concept c2                                    ON rvcm.concept_id               = c2.concept_id
                                      JOIN redcap2omop_redcap_data_dictionaries rdd           ON rv.redcap_data_dictionary_id  = rdd.id
                                      JOIN redcap2omop_redcap_projects rp                     ON rdd.redcap_project_id         = rp.id
WHERE rp.name = 'CCC19'
AND rdd.version = 2
ORDER BY rv.id, rvc.id

--latest problems
SELECT  rdd.version
      , rv.form_name
      , rv.name                   AS variable_name
      , rv.field_label            AS varaible_description
      , rv.field_type_normalized  AS field_type
      , rv.text_validation_type
      , rv.curation_status
      , rrvm.map_type             AS variable_map_type
      , rot.name                  AS variable_mapped_omop_table
      , roc.name                  AS variable_mapped_omop_column
      , c1.domain_id              AS variable_map_concept_domain_id
      , c1.vocabulary_id          AS variable_map_concept_vocabulary_id
      , c1.concept_name           AS variable_map_concept_name
      , c1.concept_code           AS variable_map_concept_code
      , c1.concept_id             AS variable_map_concept_id
      , c1.standard_concept       AS variable_map_concept_standard_concept
      , rvc.choice_code_raw       AS variable_choice_code
      , rvc.choice_description    AS variable_choice_description
	    , rvc.curation_status       AS variable_choice_curation_status
      , rvcm.map_type             AS variable_choice_map_type
      , c2.domain_id              AS variable_choice_map_concept_domain_id
      , c2.vocabulary_id          AS variable_choice_map_concept_vocabulary_id
      , c2.concept_name           AS variable_choice_map_concept_name
      , c2.concept_code           AS variable_choice_map_concept_code
      , c2.concept_id             AS variable_choice_map_concept_id
      , c2.standard_concept       AS variable_choice_map_concept_standard_concept
FROM redcap2omop_redcap_variables rv  LEFT JOIN redcap2omop_redcap_variable_maps rrvm         ON rrvm.redcap_variable_id       = rv.id
                                      LEFT JOIN redcap2omop_omop_columns roc                  ON rrvm.omop_column_id           = roc.id
                                      LEFT JOIN redcap2omop_omop_tables rot                   ON roc.omop_table_id             = rot.id
                                      LEFT JOIN concept c1                                    ON rrvm.concept_id               = c1.concept_id
                                      LEFT JOIN redcap2omop_redcap_variable_choices rvc       ON rv.id                         = rvc.redcap_variable_id
                                      LEFT JOIN redcap2omop_redcap_variable_choice_maps rvcm  ON rvc.id                        = rvcm.redcap_variable_choice_id
                                      LEFT JOIN concept c2                                    ON rvcm.concept_id               = c2.concept_id
                                      JOIN redcap2omop_redcap_data_dictionaries rdd           ON rv.redcap_data_dictionary_id  = rdd.id
                                      JOIN redcap2omop_redcap_projects rp                     ON rdd.redcap_project_id         = rp.id
WHERE rp.name = 'CCC19'
AND rdd.version = 2
AND
(
(
rv.curation_status  = 'undetermined updated variable choices'
AND
rvc.curation_status = 'undetermined new choice'
)
OR
(
rv.curation_status  = 'undetermined new variable'
)
)
ORDER BY rv.id, rvc.id

--latest deleted
SELECT  rdd.version
      , rv.form_name
      , rv.name                   AS variable_name
      , rv.field_label            AS varaible_description
      , rv.field_type_normalized  AS field_type
      , rv.text_validation_type
      , rv.curation_status
      , rv.deleted_in_next_data_dictionary
      , rrvm.map_type             AS variable_map_type
      , rot.name                  AS variable_mapped_omop_table
      , roc.name                  AS variable_mapped_omop_column
      , c1.domain_id              AS variable_map_concept_domain_id
      , c1.vocabulary_id          AS variable_map_concept_vocabulary_id
      , c1.concept_name           AS variable_map_concept_name
      , c1.concept_code           AS variable_map_concept_code
      , c1.concept_id             AS variable_map_concept_id
      , c1.standard_concept       AS variable_map_concept_standard_concept
      , rvc.choice_code_raw       AS variable_choice_code
      , rvc.choice_description    AS variable_choice_description
	    , rvc.curation_status       AS variable_choice_curation_status
      , rvc.deleted_in_next_data_dictionary
      , rvcm.map_type             AS variable_choice_map_type
      , c2.domain_id              AS variable_choice_map_concept_domain_id
      , c2.vocabulary_id          AS variable_choice_map_concept_vocabulary_id
      , c2.concept_name           AS variable_choice_map_concept_name
      , c2.concept_code           AS variable_choice_map_concept_code
      , c2.concept_id             AS variable_choice_map_concept_id
      , c2.standard_concept       AS variable_choice_map_concept_standard_concept
FROM redcap2omop_redcap_variables rv  LEFT JOIN redcap2omop_redcap_variable_maps rrvm         ON rrvm.redcap_variable_id       = rv.id
                                      LEFT JOIN redcap2omop_omop_columns roc                  ON rrvm.omop_column_id           = roc.id
                                      LEFT JOIN redcap2omop_omop_tables rot                   ON roc.omop_table_id             = rot.id
                                      LEFT JOIN concept c1                                    ON rrvm.concept_id               = c1.concept_id
                                      LEFT JOIN redcap2omop_redcap_variable_choices rvc       ON rv.id                         = rvc.redcap_variable_id
                                      LEFT JOIN redcap2omop_redcap_variable_choice_maps rvcm  ON rvc.id                        = rvcm.redcap_variable_choice_id
                                      LEFT JOIN concept c2                                    ON rvcm.concept_id               = c2.concept_id
                                      JOIN redcap2omop_redcap_data_dictionaries rdd           ON rv.redcap_data_dictionary_id  = rdd.id
                                      JOIN redcap2omop_redcap_projects rp                     ON rdd.redcap_project_id         = rp.id
WHERE rp.name = 'CCC19'
AND rdd.version = 1
AND
(
  rv.deleted_in_next_data_dictionary = true
  OR
  rvc.deleted_in_next_data_dictionary = true
)
ORDER BY rv.id, rvc.id
