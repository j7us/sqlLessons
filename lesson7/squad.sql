WITH battles AS (
    SELECT
        sb.squad_id as s_id,
        sum(sb.report_id) as all_battles,
        sum(case when sb.outcome = 'WIN' then 1 else 0 end) as win_battles,
        sum(casualties) as casual
    FROM
        SQUAD_BATTLES sb
    GROUP BY s_id
), members AS (
    SELECT
        sm.squad_id as s_id,
        sum(dw.dwarf_id) as all_members,
        sum(case when sm.end_date isnull then 1 else 0 end) as cur_members,
        avg(de.quality) as avg_qual
    FROM
        SQUAD_MEMBERS sm
    LEFT JOIN
        DWARVES dw ON sm.dwarf_id = dw.dwarf_id
    LEFT JOIN
        DWARF_EQUIPMENT de ON de.dwarf_id = dw.dwarf_id
    GROUP BY s_id
)
SELECT
    ms.squad_id as squad_id,
    ms.name as squad_name,
    ms.formation_type as formation_type,
    dw.name as leader_name,
    b.all_battles as total_battles,
    b.win_battles as victories,
    COALESCE(ROUND(b.win_battles::DECIMAL/b.all_battles * 100, 2), 0) as victory_percentage,
    b.casual as casualty_rate,
    m.cur_members as current_members,
    m.all_members as total_members_ever,
    COALESCE(ROUND(m.cur_members::DECIMAL/m.all_members * 100, 2), 0) as retention_rate,
    m.avg_qual as avg_equipment_quality,
    t.count_trains as total_training_sessions,
    corr(t.count_trains, b.win_battles) as training_battle_correlation,
    JSON_OBJECT(
            'member_ids', (
        SELECT JSON_ARRAYAGG(sm1.dwarf_id)
        FROM SQUAD_MEMBERS sm1
        WHERE sm1.squad_id = ms.squad_id
    ),
            'equipment_ids', (
                SELECT JSON_ARRAYAGG(DISTINCT se1.equipment_id)
                FROM SQUAD_EQUIPMENT se1
                WHERE se1.squad_id = ms.squad_id
            ),
            'battle_report_ids', (
                SELECT JSON_ARRAYAGG(DISTINCT sb1.report_id)
                FROM SQUAD_BATTLES sb1
                WHERE sb1.squad_id = ms.squad_id
            ),
            'training_ids', (
                SELECT JSON_ARRAYAGG(st1.schedule_id)
                FROM SQUAD_TRAINING st1
                WHERE st1.squad_id = st1.squad_id
            )
    ) AS related_entities
FROM
    MILITARY_SQUADS ms
LEFT JOIN
    DWARVES dw ON ms.leader_id = dw.dwarf_id
LEFT JOIN
    battles b ON b.s_id = ms.squad_id
LEFT JOIN
    members m ON m.s_id = ms.squad_id
LEFT JOIN
    (SELECT sum(st.frequency) as count_trains,
            st.squad_id
     FROM SQUAD_TRAINING st
     GROUP BY st.squad_id) as t ON ms.squad_id = t.squad_id

