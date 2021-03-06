SELECT  rv.name
      , rv.form_name
      , rv.field_type
      , rv.field_type_normalized
      , rv.text_validation_type
      , rv.curation_status
      , rv.field_type_curated
FROM redcap2omop_redcap_variables rv LEFT JOIN redcap2omop_redcap_variable_choices rvc ON rv.id                         = rvc.redcap_variable_id
                                     JOIN redcap2omop_redcap_data_dictionaries rdd     ON rv.redcap_data_dictionary_id  = rdd.id
                                     JOIN redcap2omop_redcap_projects rp               ON rdd.redcap_project_id         = rp.id
WHERE rp.name = 'CCC19'
ORDER By rv.id

select  rv.*
     ,  rvc.*
from redcap2omop_redcap_variables rv
    left join redcap2omop_redcap_variable_choices rvc on rv.id = rvc.redcap_variable_id
    join redcap2omop_redcap_data_dictionaries rdd on rv.redcap_data_dictionary_id = rdd.id
    join redcap2omop_redcap_projects rp on rdd.redcap_project_id = rp.id
where rp.name = 'Data Migration Sandbox -- PPA'

select *
from redcap2omop_redcap_export_tmps

select   redcap_event_name
        , v_d
        , v_coordinator
        , moca
from redcap2omop_redcap_export_tmps
--where moca is not null
--and moca!= ''
order by  redcap_event_name, redcap_export_tmps.id, v_d


select  rv.id
      , rv.name
      , rv.form_name
      , rv.field_type
      , rv.field_type_normalized
      , rv.field_label
      , rv.text_validation_type
      , rv.field_annotation
      , rv.field_type_curated
      , rvc.choice_code_raw
      , rvc.choice_code_concept_code
      , rvc.choice_description
from redcap_variables rv left join redcap_variable_choices rvc on rv.id = rvc.redcap_variable_id
                         join redcap_data_dictionaries rdd on rv.redcap_data_dictionary_id = rdd.id
                         join redcap_projects rp on rdd.redcap_project_id = rp.id
where rp.name = 'REDCap2SQL -- sandbox 2 - Longitudinal'
order by rv.id

select  rv.id
      , rv.name
      , rv.form_name
      , rv.field_type
      , rv.field_type_normalized
      , rv.field_label
      , rv.text_validation_type
      , rv.field_annotation
      , rv.field_type_curated
      , rvc.choice_code_raw
      , rvc.choice_code_concept_code
      , rvc.choice_description
from redcap_variables rv left join redcap_variable_choices rvc on rv.id = rvc.redcap_variable_id
                         join redcap_data_dictionaries rdd on rv.redcap_data_dictionary_id = rdd.id
                         join redcap_projects rp on rdd.redcap_project_id = rp.id
where rp.name = 'CCC19'
--and rv.name = 'hcw'
and rv.id > 483
order by rv.id


select *
from redcap_records_tmp_1


select *
from person


select  p.person_source_value
      , rp.name
      , rv.name
      , c1.concept_name
      , o.value_as_number
      , o.value_as_concept_id
      , o.value_as_string
      , c2.concept_name
      , o.observation_source_value
      , pr.provider_source_value
from observation o left join concept c1 on o.observation_concept_id = c1.concept_id
                   left join concept c2 on o.value_as_concept_id = c2.concept_id
        				   join redcap2omop_redcap_source_links rsl on o.observation_id = rsl.redcap_sourced_id  and rsl.redcap_sourced_type = 'Redcap2omop::Observation'
        				   join redcap2omop_redcap_variables rv on rv.id = rsl.redcap_source_id
                   join redcap2omop_redcap_data_dictionaries rdd on rv.redcap_data_dictionary_id = rdd.id
                   join redcap2omop_redcap_projects rp on rdd.redcap_project_id = rp.id
                   join person p on o.person_id = p.person_id
                   left join provider pr on o.provider_id = pr.provider_id


select   p.person_source_value
       , rp.name
       , rv.name
       , c1.concept_name
       , m.value_as_number
       , m.value_as_concept_id
       , c2.concept_name
       , m.measurement_source_value
       , pr.provider_source_value
from measurement m left join concept c1 on m.measurement_concept_id = c1.concept_id
                   left join concept c2 on m.value_as_concept_id = c2.concept_id
         				   join redcap2omop_redcap_source_links rsl on m.measurement_id = rsl.redcap_sourced_id and rsl.redcap_sourced_type = 'Redcap2omop::Measurement'
         				   join redcap2omop_redcap_variables rv on rv.id = rsl.redcap_source_id
                   join redcap2omop_redcap_data_dictionaries rdd on rv.redcap_data_dictionary_id = rdd.id
                   join redcap2omop_redcap_projects rp on rdd.redcap_project_id = rp.id
                   join person p on m.person_id = p.person_id
                   left join provider pr on m.provider_id = pr.provider_id

select  p.person_source_value
      , rp.name
      , rv.name
      , c1.concept_name
      , de.device_source_value
      , pr.provider_source_value
from device_exposure de left join concept c1 on de.device_concept_id = c1.concept_id
         				        join redcap_source_links rsl on de.device_exposure_id = rsl.redcap_sourced_id and rsl.redcap_sourced_type = 'DeviceExposure'
         				        join redcap_variables rv on rv.id = rsl.redcap_source_id
                        join redcap_data_dictionaries rdd on rv.redcap_data_dictionary_id = rdd.id
                        join redcap_projects rp on rdd.redcap_project_id = rp.id
                        join person p on de.person_id = p.person_id
                        left join provider pr on de.provider_id = pr.provider_id
