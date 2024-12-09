-- Получить информацию о всех гномах, которые входят в какой-либо отряд, вместе с информацией об их отрядах.
select D.name AS DwarfName,
       D.profession AS Profession,
       S.name AS SquadName,
       S.mission AS Mission
from dwarves D
join squads S
on D.squad_id = S.squad_id;
-- Стоило использовать alias исходных таблиц для менее захламленных наименований,
-- не выводить лишнюю информацию в результате и корректно называть столбцы.




-- Найти всех гномов с профессией "miner", которые не состоят ни в одном отряде.
select name,
       age
from dwarves
where squad_id isnull and profession = 'miner';
-- Не стоило выводить лишнюю информацию, например id.




-- Получить все задачи с наивысшим приоритетом, которые находятся в статусе "pending".
select task_id,
       description,
       assigned_to
from tasks
where tasks.priority = (select max(priority) from tasks where status = 'pending')
    and tasks.status = 'pending';
-- Уточнил в подзапросе, что нужно искать наивысший приоритет именно среди статуса 'pending'




-- Для каждого гнома, который владеет хотя бы одним предметом, получить количество предметов, которыми он владеет.
select D.name AS DwarfName,
       D.profession AS Profession,
       COUNT(I.item_id) AS ItemCount
from dwarves D
join items I
on D.dwarf_id = I.owner_id
group by dwarf_id;
-- Стоило использовать alias исходных таблиц для менее захламленных наименований
-- и использовать названия для результирующих столбцов.




-- Получить список всех отрядов и количество гномов в каждом отряде. Также включите в выдачу отряды без гномов.
SELECT
    S.squad_id,
    S.name AS SquadName,
    COUNT(D.dwarf_id) AS NumberOfDwarves
FROM
    Squads S
LEFT JOIN
    Dwarves D
ON
    S.squad_id = D.squad_id
GROUP BY
    S.squad_id, S.name;
-- Стоило использовать alias исходных таблиц для менее захламленных наименований
-- и использовать названия для результирующих столбцов.




-- Получить список профессий с наибольшим количеством незавершённых задач ("pending" и "in_progress") у гномов этих профессий.

-- Отправленный вариант
with professions_with_count as (
    select dwarves.profession, count(*) as count_dwarf
    from dwarves
    join tasks
    on dwarves.dwarf_id = tasks.assigned_to
    where tasks.status in ('pending', 'in_progress')
    group by dwarves.profession
)
select professions_with_count.profession
from professions_with_count
where count_dwarf = (select max(count_dwarf) from professions_with_count);

-- Правильное решение
SELECT
    D.profession,
    COUNT(T.task_id) AS UnfinishedTasksCount
FROM
    Dwarves D
JOIN
    Tasks T
ON
    D.dwarf_id = T.assigned_to
WHERE
    T.status IN ('pending', 'in_progress')
GROUP BY
    D.profession
ORDER BY
    UnfinishedTasksCount DESC;
-- В данном случае не правильно понял название и попытался найти именно наибольшее кол-во задач




-- Для каждого типа предметов узнать средний возраст гномов, владеющих этими предметами.
SELECT
    I.type AS ItemType,
    AVG(D.age) AS AverageAge
FROM
    Items I
JOIN
    Dwarves D
ON
    I.owner_id = D.dwarf_id
GROUP BY
    I.type;
-- Стоило использовать alias исходных таблиц для менее захламленных наименований
-- и использовать названия для результирующих столбцов.




-- Найти всех гномов старше среднего возраста (по всем гномам в базе), которые не владеют никакими предметами.

-- Отправленный вариант
select *
from dwarves
left join items
on dwarves.dwarf_id = items.owner_id
where items.item_id is null
and dwarves.age > (select avg(age) from dwarves);

-- Правильное решение
SELECT
    D.name,
    D.age,
    D.profession
FROM
    Dwarves D
WHERE
    D.age > (SELECT AVG(age) FROM Dwarves)
    AND D.dwarf_id NOT IN (SELECT owner_id FROM Items);
-- Стоило использовать alias исходных таблиц для менее захламленных наименований
-- и использовать подзапрос вместо join