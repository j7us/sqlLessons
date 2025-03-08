SELECT e.expedition_id,
       e.destination,
       e.status,
       (select round(((select count(*)
                      from EXPEDITION_MEMBERS em1
                      where em1.expedition_id = e.expedition_id and em1.survived = true) :: numeric / count(*)) * 100, 2)
        from EXPEDITION_MEMBERS em
        where em.expedition_id = e.expedition_id) as survival_rate,
       (select sum(ea.value) from EXPEDITION_ARTIFACTS ea where ea.expedition_id = e.expedition_id) as artifacts_value,
       (select count(*) from EXPEDITION_SITES es where es.expedition_id = e.expedition_id) as discovered_sites,
       (select round(((select count(*)
                       from EXPEDITION_CREATURES ec1
                       where ec1.expedition_id = e.expedition_id and ec1.outcome = 'success') :: numeric / count(*)) * 100, 2)
        from EXPEDITION_CREATURES ec
        where ec.expedition_id = e.expedition_id) as encounter_success_rate,
        DATEDIFF(day, e.departure_date, e.return_date) as expedition_duration,
       JSON_OBJECT(
            'member_ids', (
                SELECT JSON_ARRAYAGG(eml.dwarf_id)
                FROM EXPEDITION_MEMBERS eml
                WHERE eml.expedition_id = e.expedition_id
            ),
            'artifact_ids', (
                SELECT JSON_ARRAYAGG(eal.artifact_id)
                FROM EXPEDITION_ARTIFACTS eal
                WHERE eal.expedition_id = e.expedition_id
            ),
            'site_ids', (
                SELECT JSON_ARRAYAGG(esl.site_id)
                FROM EXPEDITION_SITES esl
                WHERE esl.expedition_id = e.expedition_id
                ))
FROM EXPEDITIONS e;