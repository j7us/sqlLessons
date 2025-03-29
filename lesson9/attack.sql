WITH creatures AS (
    SELECT
        c.type as creature_type,
        coalesce(avg(c.threat_level), 0) as threat_level,
        coalesce(count(ca.attack_id), 0) as count_attack, -- Потом сложить? чтобы посчитать сколько атак всего
        coalesce(avg(ct.distance_to_fortress), 0) as territory_proximity,
        max(ca.date) as last_sighting_date,
        coalesce(sum(c.estimated_population), 0) as estimated_numbers,
        JSON_ARRAYAGG(c.creature_id) as creature_ids
    FROM
        CREATURE_ATTACKS ca
    JOIN
        CREATURES c ON ca.creature_id = c.creature_id
    LEFT JOIN
        CREATURE_TERRITORIES ct ON ct.creature_id = c.creature_id
    GROUP BY type
), attack_count AS (
    SELECT
        coalesce(sum(count_attack), 0) as attacks,
        coalesce(count(type), 0) as attackers
    FROM creatures
), locations as (
    SELECT
        l.zone_id as zone_id,
        l.name as zone_name,
        ROUND((attack_res.wins::DECIMAL / NULLIF(attack_count.attacks, 0)) * 100, 2) as vulnerability_score,
        attack_count.attacks - wins as historical_breaches,
        l.fortification_level as fortification_level,
        JSON_OBJECT(
                'structure_ids', (SELECT JSON_ARRAYAGG(ds.structure_id)
                                  FROM Defense_Structures ds
                                  WHERE ds.location_id = l.location_id),
                'squad_ids', (SELECT JSON_ARRAYAGG(sm.squad_id)
                              FROM Squad_Movement sm
                              WHERE sm.location_id = l.location_id)
        ) as defense_coverage
    FROM
        LOCATIONS l
    LEFT JOIN
        (SELECT sum(case when ca1.outcome = 'WIN' then 1 else 0 end) as wins,
                ca1.location_id as location_id
         FROM CREATURE_ATTACKS ca1
         GROUP BY location_id) as attack_res ON attack_res.location_id = l.location_id
    LEFT JOIN
        attack_count ON true
), def AS (
    SELECT
        ca_def.defense_structures_used as defense_type,
        avg(ca_def.casualties) as avg_enemy_casualties
    FROM
        CREATURE_ATTACKS ca_def
), squad as (
    SELECT
        ms.squad_id as squad_id,
        ms.name as squad_name,
        count(when sm.exit_reason = null then 1 end) as active_members,
        avg(ds.level) as avg_skills,
        JSON_ARRAYAGG(
                JSON_OBJECT(
                        'zone_id', mczl.zone_id,
                        'response_time', mcz.response_time
                )) as response_coverage
    FROM
        MILITARY_SQUADS ms
            LEFT JOIN
        SQUAD_MEMBERS sm ON ms.squad_id = sm.squad_id
            LEFT JOIN
        DWARVES d ON d.dwarf_id = sm.dwarf_id
            LEFT JOIN
        DWARF_SKILLS ds ON ds.dwarf_id = d.dwarf_id
            LEFT JOIN
        Military_Coverage_Zones mcz ON ms.squad_id = mcz.squad_id
            LEFT JOIN
        LOCATIONS mczl ON mczl.location_id = mcz.location_id
    GROUP BY squad_id, squad_name
), dates as (
    SELECT
        extract(YEAR FROM ca_date.date) as year,
        count(ca_date.attack_id) as total_attacks,
        sum(ca_date.casualties) as casualties
    FROM
        CREATURE_ATTACKS ca_date
    GROUP BY year
    ORDER BY year
)
SELECT
    (SELECT attack_count.attacks FROM attack_count) as total_recorded_attacks,
    (SELECT attack_count.attackers FROM attack_count) as unique_attackers,
    (SELECT avg(vulnerability_score) FROM locations) as overall_defense_success_rate,
    JSON_OBJECT(
        'threat_assessment',
        (SELECT JSON_ARRAYAGG(
                creature_type,
                threat_level,
                last_sighting_date,
                territory_proximity,
                estimated_numbers,
                creature_ids
                )
         FROM creatures c),
        'vulnerability_analysis',
        (SELECT JSON_ARRAYAGG(
                zone_id,
                zone_name,
                vulnerability_score,
                historical_breaches,
                fortification_level,
                defense_coverage
                )
         FROM locations),
        'defense_effectiveness',
        (SELECT JSON_ARRAYAGG(
                defense_type,
                avg_enemy_casualties
                )
         FROM def),
        'military_readiness_assessment',
        (SELECT JSON_ARRAYAGG(
                squad_id,
                squad_name,
                active_members,
                response_coverage
                )
         FROM squad),
        'security_evolution',
        (SELECT JSON_ARRAYAGG(
                year,
                total_attacks,
                casualties
                )
         FROM dates)
    ) as security_analysis
FROM (SELECT 1) AS dummy;



