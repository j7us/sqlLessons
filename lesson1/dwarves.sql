-- Получить информацию о всех гномах, которые входят в какой-либо отряд, вместе с информацией об их отрядах.
select dwarf_id, dwarves.name, dwarves.age, dwarves.profession, squads.*
from dwarves
join squads
on dwarves.squad_id = squads.squad_id;




-- Найти всех гномов с профессией "miner", которые не состоят ни в одном отряде.
select *
from dwarves
where squad_id isnull and profession = 'miner';




-- Получить все задачи с наивысшим приоритетом, которые находятся в статусе "pending".
select *
from tasks
where tasks.priority = (select max(priority)
                        from tasks)
    and tasks.status = 'pending';




-- Для каждого гнома, который владеет хотя бы одним предметом, получить количество предметов, которыми он владеет.
select dwarf_id, count(*)
from dwarves
join items
on dwarves.dwarf_id = items.owner_id
group by dwarf_id;




-- Получить список всех отрядов и количество гномов в каждом отряде. Также включите в выдачу отряды без гномов.
select squad_id, name, count(dwarf_id)
from squads
left join dwarves
on squads.squad_id = dwarves.squad_id
group by squad_id, name;




-- Получить список профессий с наибольшим количеством незавершённых задач ("pending" и "in_progress") у гномов этих профессий.
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




-- Для каждого типа предметов узнать средний возраст гномов, владеющих этими предметами.
select items.type, avg(dwarves.age)
from items
join dwarves
on items.owner_id = dwarves.dwarf_id
group by items.type;




-- Найти всех гномов старше среднего возраста (по всем гномам в базе), которые не владеют никакими предметами.
select *
from dwarves
left join items
on dwarves.dwarf_id = items.owner_id
where items.item_id is null
and dwarves.age > (select avg(age) from dwarves);