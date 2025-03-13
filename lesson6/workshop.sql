WITH
    wp_grouped AS (
        SELECT
            wp.workshop_id as w_id,
            coalesce(sum(wp.quantity), 0) as total_quantity,
            min(wp.production_date) as min_produced_day,
            max(wp.production_date) as max_produced_day,
            coalesce(sum(p.value), 0) as total_value
        FROM
            WORKSHOP_PRODUCTS wp
                LEFT JOIN
            PRODUCTS p ON p.product_id = wp.product_id
        GROUP BY wp.workshop_id
),  w_grouped AS (
    SELECT
        w.workshop_id as w_id,
        w.name as w_name,
        w.type as w_type,
        w.quality as w_qual,
        coalesce(count(wc.dwarf_id), 0) as w_dwar,
        coalesce(sum(wm.quantity), 1) as material_quntity,
        coalesce(sum(dw_lvl_grouped.dw_lvl), 0) as lvl_sum
    FROM
        WORKSHOPS w
            LEFT JOIN
        WORKSHOP_CRAFTSDWARVES wc ON wc.workshop_id = w.workshop_id
            LEFT JOIN
        (SELECT
             d.dwarf_id as dw_id,
             ds.level as dw_lvl
         FROM
             DWARVES d
         LEFT JOIN
            DWARF_SKILLS ds ON ds.dwarf_id = d.dwarf_id) as dw_lvl_grouped ON dw_lvl_grouped.dw_id = wc.dwarf_id
            LEFT JOIN
        WORKSHOP_MATERIALS wm ON wm.workshop_id = w.workshop_id and is_input = true
    GROUP BY w_id, w_name, w_type, w_qual

),
    average_skill as (
        SELECT
            w_grouped.w_id as id,
            w_grouped.lvl_sum/coalesce(w_grouped.w_dwar, 1) as av_lvl
        FROM w_grouped
    )
SELECT
    wg.w_id as workshop_id,
    wg.w_name as workshop_name,
    wg.w_type as workshop_type,
    wg.w_dwar as num_craftsdwarves,
    wp_grouped.total_quantity as total_quantity_produced,
    wp_grouped.total_value as total_production_value,
    wp_grouped.total_quantity/coalesce(EXTRACT(DAY FROM (wp_grouped.max_produced_day - wp_grouped.min_produced_day)), 1) as daily_production_rate,
    wp_grouped.total_value/wg.material_quntity as value_per_material_unit,
    wp_grouped.total_quantity/wg.material_quntity as material_conversion_ratio,
    average_skill.av_lvl as average_craftsdwarf_skill,
    (average_skill.av_lvl/wg.w_qual)*100 as skill_quality_correlation,
    JSON_OBJECT(
            'craftsdwarf_ids', (
        SELECT JSON_ARRAYAGG(wc1.dwarf_id)
        FROM WORKSHOP_CRAFTSDWARVES wc1
        WHERE wc1.workshop_id = wg.workshop_id
    ),
            'product_ids', (
                SELECT JSON_ARRAYAGG(wp1.product_id)
                FROM WORKSHOP_PRODUCTS wp1
                WHERE wp1.workshop_id = wg.workshop_id
            ),
            'material_ids', (
                SELECT JSON_ARRAYAGG(wm1.material_id)
                FROM WORKSHOP_MATERIALS wm1
                WHERE wm1.workshop_id = wg.workshop_id
            ),
            'project_ids', (
                SELECT JSON_ARRAYAGG(pr1.project_id)
                FROM PROJECTS pr1
                WHERE pr1.workshop_id = wg.workshop_id
                )
    ) AS related_entities
FROM
    w_grouped wg
LEFT JOIN
    wp_grouped ON wp_grouped.w_id = wg.w_id
LEFT JOIN
    average_skill ON average_skill.id = wg.w_id