-- Найдите все отряды, у которых нет лидера.
select squad_id,
       name
from squads
where leader_id is null;
-- Совпадает с эталонным решением.




-- Получите список всех гномов старше 150 лет, у которых профессия "Warrior".
SELECT
    dwarf_id,
    name
FROM
    dwarves
WHERE
    age > 150
    and profession = 'Warrior';
-- Совпадает с эталонным решением.




-- Найдите гномов, у которых есть хотя бы один предмет типа "weapon".
SELECT
    D.name,
    D.profession
FROM
    dwarves D
JOIN
    items I
ON
    D.dwarf_id = I.owner_id
WHERE
    I.type = 'weapon';
-- Совпадает с эталонным решением.




-- Получите количество задач для каждого гнома, сгруппировав их по статусу.
SELECT
    D.dwarf_id,
    D.name,
    D.profession,
    T.status,
    count(T.task_id)
FROM
    dwarves D
JOIN
    tasks T
ON
    D.dwarf_id = T.assigned_to
GROUP BY
    D.dwarf_id,
    D.name,
    D.profession,
    T.status;
-- Был использован лищний JOIN без необходимости




-- Найдите все задачи, которые были назначены гномам из отряда с именем "Guardians".
SELECT
    T.description,
    T.status
FROM
    dwarves D
JOIN
    squads S
ON
    D.squad_id = S.squad_id
JOIN
    tasks T
ON
    D.dwarf_id = T.assigned_to
WHERE
    S.name = 'Guardians';
-- Совпадает с эталонным решением.




-- Выведите всех гномов и их ближайших родственников, указав тип родственных отношений.
SELECT
    D.name,
    R.relationship,
    DR.name
FROM
    dwarves D
JOIN
    relationships R
ON
    D.dwarf_id = R.dwarf_id
JOIN
    dwarves DR
ON
    R.related_to = DR.dwarf_id;
-- Совпадает с эталонным решением.