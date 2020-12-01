select *
from redcap_variables rv left join redcap_variable_choices rvc on rv.id = rvc.redcap_variable_id


select *
from redcap_export_tmps

select   redcap_event_name
        , v_d
        , v_coordinator
        , moca
from redcap_export_tmps
--where moca is not null
--and moca!= ''
order by  redcap_event_name, redcap_export_tmps.id, v_d

select *
from person

select  c1.concept_name
      , o.value_as_number
      , o.value_as_concept_id
      , o.value_as_string
      , c2.concept_name
from observation o left join concept c1 on o.observation_concept_id = c1.concept_id
                   left join concept c2 on o.value_as_concept_id = c2.concept_id




SELECT *
FROM public.core_records_tmp