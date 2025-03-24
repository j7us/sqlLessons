WITH civil AS (
    SELECT
        c_for_json.fortress_id as fortress_id,
        c_for_json.civilization_type as civilization_type,
        coalesce(count(c_for_json.caravan_id), 0) as total_caravans,
        coalesce(sum(tt_for_json.value), 0) as total_trade_value,
        coalesce(sum(t_for_json.balance), 0) as trade_balance,
        t_for_json.relathionship as trade_relationship,
        CORR(tt_for_json.value, de_for_json.outcome) as diplomatic_correlation,
        JSON_ARRAYAGG(c_for_json.caravan_id) as caravan_ids
    FROM
        TRADERS t_for_json
            LEFT JOIN
        CARAVANS c_for_json ON c_for_json.caravan_id = t_for_json.caravan_id
            LEFT JOIN
        TRADE_TRANSACTIONS tt_for_json ON tt_for_json.caravan_id = c_for_json.caravan_id
            LEFT JOIN
        (SELECT de1.caravan_id as caravan_id,
                (case when de1.outcome = 'Favorable' then 1 else -1 end) as outcome
         FROM DIPLOMATIC_EVENTS de1) as de_for_json ON de_for_json.caravan_id = c_for_json.caravan_id
    GROUP BY fortress_id, c_for_json.civilization_type, t_for_json.relathionship
), export AS (
    SELECT
        w.fortress_id as fortress_id,
        w.type as workshop_type,
        p.type as product_type,
        avg(wp.markup) as avg_markup,
        JSON_ARRAYAGG(w.workshop_id) as workshop_ids
    FROM
        WORKSHOPS w
            JOIN
        WORKSHOP_PRODUCTS wp ON w.workshop_id = wp.workshop_id
            JOIN
        PRODUCTS p ON wp.product_id = p.product_id
    GROUP BY w.fortress_id, workshop_type, product_type
), timeline AS (
    SELECT
        c1.fortress_id as fortress_id,
        extract(YEAR FROM tt1.date) as year,
        extract(QUARTER FROM tt1.date) as quarter,
        coalesce(sum(tt1.value), 0) as quarterly_value,
        coalesce(sum(t1.balance), 0) as quarterly_balance,
        coalesce(count(distinct tt1.transaction_id), 0) as trade_diversity
    FROM
        TRADERS t1
            JOIN
        CARAVANS c1 ON t1.caravan_id = c1.caravan_id
            LEFT JOIN
        TRADE_TRANSACTIONS tt1 ON tt1.caravan_id = t1.caravan_id
    GROUP BY fortress_id, year, quarter
    ORDER BY year, quarter
)
SELECT
    count(DISTINCT t.trader_id) as total_trading_partners,
    sum(tt.value) as all_time_trade_value,
    sum(t.balance) as all_time_trade_balance,
    JSON_OBJECT(
        'civilization_data',
        (SELECT
             JSON_ARRAY(
                JSON_OBJECT(
                    'civilization_type', civilization_type,
                    'total_caravans', total_caravans,
                    'total_trade_value', total_trade_value,
                    'trade_balance', trade_balance,
                    'trade_relationship', trade_relationship,
                    'diplomatic_correlation', diplomatic_correlation,
                    'caravan_ids', caravan_ids
                )
             )
         FROM civil
         WHERE civil.fortress_id = f.fortress_id)
    ),
    JSON_OBJECT(
        'export_effectiveness',
        (SELECT
             JSON_ARRAY(
                JSON_OBJECT(
                    'workshop_type', workshop_type,
                    'product_type', product_type,
                    'avg_markup', avg_markup,
                    'workshop_ids', workshop_ids
                )
             )
         FROM export
         WHERE export.fortress_id = f.fortress_id)
    ),
    JSON_OBJECT(
        'export_effectiveness',
        (SELECT
             JSON_ARRAY(
                JSON_OBJECT(
                    'year', year,
                    'quarter', quarter,
                    'quarterly_value', quarterly_value,
                    'quarterly_balance', quarterly_balance,
                    'trade_diversity', trade_diversity
                )
             )
        FROM timeline
        WHERE timeline.fortress_id = f.fortress_id)
    )
FROM
    FORTRESSES f
LEFT JOIN
    CARAVANS c ON c.fortress_id = f.fortress_id
LEFT JOIN
    TRADERS t ON c.caravan_id = t.caravan_id
LEFT JOIN
    TRADE_TRANSACTIONS tt ON tt.caravan_id = c.caravan_id
GROUP BY f.fortress_id;

