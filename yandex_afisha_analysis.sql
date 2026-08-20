/* 
 * Проект «Яндекс Афиша»
 *
 * Цель проекта: изучить данные о заказах билетов, мероприятиях, площадках,
 * городах и регионах, чтобы подготовить аналитическую основу для оценки спроса,
 * сезонности и пользовательского поведения.
 *
 * Автор: Марс Омурбеков
 * Дата: 06.05.2026
 */

-------------------------------------------------------------------------------------------------------------------------------------

-- Часть 1. Знакомство с данными


-- 1.1. Обзор структуры базы данных
-- Цель: определить основные таблицы базы данных, их роли и связи между ними.
--
-- В базе используются следующие таблицы:
-- purchases — основная фактовая таблица заказов.
-- events — таблица с информацией о мероприятиях.
-- venues — справочник площадок.
-- city — справочник городов.
-- regions — справочник регионов.
--
-- Основная аналитическая связка проекта: purchases -> events.
-- Таблица purchases содержит факты заказов, а events добавляет характеристики мероприятий.
--
-- Основные связи:
-- purchases.event_id -> events.event_id
-- events.venue_id -> venues.venue_id
-- events.city_id -> city.city_id
-- city.region_id -> regions.region_id
--
-- Вывод:
-- Основная таблица для дальнейшего анализа — purchases.
-- Для детализации заказов по типам мероприятий, городам и площадкам
-- используется таблица events и справочники venues, city, regions.


-------------------------------------------------------------------------------------------------------------------------------------

-- 1.2. Проверка объёма таблиц и уникальности ключей
-- Цель: проверить размер таблиц и уникальность ключевых идентификаторов.
-- Если количество строк совпадает с количеством уникальных ключей,
-- значит дубликатов по ключевому полю нет.

-- 1.2.1. Таблица purchases
SELECT 
    count(*) AS total_rows,
    count(DISTINCT user_id) AS total_users,
    count(DISTINCT order_id) AS unique_orders,
    count(*) - count(DISTINCT order_id) AS duplicate_orders
FROM purchases;


-- 1.2.2. Таблица events
SELECT 
    count(*) AS total_rows,
    count(DISTINCT event_id) AS unique_events,
    count(*) - count(DISTINCT event_id) AS duplicate_events
FROM events;


-- 1.2.3. Справочные таблицы
SELECT 
    'city' AS table_name,
    count(*) AS total_rows,
    count(DISTINCT city_id) AS unique_keys,
    count(*) - count(DISTINCT city_id) AS duplicate_keys
FROM city
---
UNION ALL 
---
SELECT 
    'venues' AS table_name,
    count(*) AS total_rows,
    count(DISTINCT venue_id) AS unique_keys,
    count(*) - count(DISTINCT venue_id) AS duplicate_keys
FROM venues
---
UNION ALL 
---
SELECT 
    'regions' AS table_name,
    count(*) AS total_rows,
    count(DISTINCT region_id) AS unique_keys,
    count(*) - count(DISTINCT region_id) AS duplicate_keys
FROM regions;


-- 1.2.4. Проверка уникальности событий по event_id и event_name_code
SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT event_id) AS unique_event_id,
    COUNT(DISTINCT event_name_code) AS unique_event_name_code,
    COUNT(DISTINCT event_id) - COUNT(DISTINCT event_name_code) AS difference
FROM events;


-- 1.2.5. Проверка количества городов и регионов
SELECT
    'city' AS table_name,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT city_id) AS unique_ids
FROM city
---
UNION ALL
---
SELECT
    'regions' AS table_name,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT region_id) AS unique_ids
FROM regions;


-- Вывод:
-- В основных таблицах purchases и events ключевые идентификаторы уникальны:
-- order_id — 292 034 уникальных значения, event_id — 22 484 уникальных значения.
-- В справочниках city, venues и regions дубликаты по ключам также не обнаружены.
-- Таблицы можно использовать для дальнейших JOIN без риска раздутия строк
-- из-за повторяющихся ключей.
--
-- Дополнительно была проверена уникальность событий по event_id и event_name_code.
-- Количество уникальных event_id составляет 22 484, а количество уникальных
-- event_name_code — 15 287. Это означает, что одному названию события
-- может соответствовать несколько разных событий.
--
-- В справочниках представлено 353 уникальных города и 81 уникальный регион.


-------------------------------------------------------------------------------------------------------------------------------------

-- 1.3. Проверка связей между таблицами
-- Цель: проверить, корректно ли таблицы связаны между собой
-- и не будет ли потери данных при объединении.
--
-- Проверяемые связи:
-- purchases -> events
-- events -> venues
-- events -> city
-- city -> regions

-- 1.3.1. Проверка связи purchases -> events
SELECT 
	count(*) AS missing_events_count
FROM purchases p 
LEFT JOIN events e 
	ON p.event_id = e.event_id
WHERE e.event_id IS NULL;


-- 1.3.2. Проверка связи events -> venues
SELECT 
	count(*) AS missing_venues_count
FROM events e 
LEFT JOIN venues v  
	ON e.venue_id = v.venue_id
WHERE v.venue_id IS NULL;


-- 1.3.3. Проверка связи events -> city
SELECT 
	count(*) AS missing_cities_count
FROM events e 
LEFT JOIN city c  
	ON e.city_id  = c.city_id
WHERE c.city_id IS NULL;


-- 1.3.4. Проверка связи city -> regions
SELECT 
	count(*) AS missing_regions_count
FROM city c 
LEFT JOIN regions r   
	ON c.region_id = r.region_id 
WHERE r.region_id IS NULL;


-- Вывод:
-- Проверка связей между таблицами показала, что все проверенные связи корректны.
-- По связям purchases -> events, events -> venues, events -> city и city -> regions
-- количество несвязанных записей равно 0.
-- Это означает, что при объединении таблиц по указанным ключам потери строк
-- из основных таблиц не ожидается.

-------------------------------------------------------------------------------------------------------------------------------------

-- 1.4. Проверка пропусков
-- Цель: определить наличие пропусков в ключевых аналитических полях.
--
-- Ключевые поля purchases:
-- order_id, user_id, event_id, created_dt_msk, revenue, total,
-- tickets_count, device_type_canonical, currency_code.
--
-- Ключевые поля events:
-- event_id, event_type_main, event_type_description, organizers,
-- city_id, venue_id.

-- 1.4.1. Проверка пропусков в purchases
SELECT
    COUNT(*) - COUNT(order_id) AS missing_order_id,
    COUNT(*) - COUNT(user_id) AS missing_user_id,
    COUNT(*) - COUNT(event_id) AS missing_event_id,
    COUNT(*) - COUNT(created_dt_msk) AS missing_created_dt_msk,
    COUNT(*) - COUNT(revenue) AS missing_revenue,
    COUNT(*) - COUNT(total) AS missing_total,
    COUNT(*) - COUNT(tickets_count) AS missing_tickets_count,
    COUNT(*) - COUNT(device_type_canonical) AS missing_device_type_canonical,
    COUNT(*) - COUNT(currency_code) AS missing_currency_code
FROM purchases;


-- 1.4.2. Проверка пропусков в events
SELECT 
    COUNT(*) - COUNT(event_id) AS missing_event_id,
    COUNT(*) - COUNT(event_type_main) AS missing_event_type_main,
    COUNT(*) - COUNT(event_type_description) AS missing_event_type_description,
    COUNT(*) - COUNT(organizers) AS missing_organizers,
    COUNT(*) - COUNT(city_id) AS missing_city_id,
    COUNT(*) - COUNT(venue_id) AS missing_venue_id
 FROM events;


-- Вывод:
-- В ключевых аналитических полях таблиц purchases и events пропуски не обнаружены.
-- Это означает, что данные можно использовать для дальнейшего анализа заказов,
-- пользователей, мероприятий, выручки, количества билетов, устройств, городов
-- и площадок без дополнительной обработки пропущенных значений.

-------------------------------------------------------------------------------------------------------------------------------------

-- 1.5. Проверка периода данных
-- Цель: определить временной охват заказов и возможность анализа сезонности.

-- 1.5.1. Минимальная и максимальная дата заказа
SELECT
	MIN(created_dt_msk::date) AS min_date, 
	MAX(created_dt_msk::date) AS max_date
FROM purchases p;


-- 1.5.2. Проверка наличия данных по месяцам
SELECT 
	date_trunc('MONTH', created_dt_msk)::date AS months, 
	count(DISTINCT order_id) AS total_orders
FROM purchases p 
GROUP BY months
ORDER BY months;


-- Вывод:
-- Данные охватывают период с 1 июня по 31 октября 2024 года.
-- Внутри периода представлены все месяцы: июнь, июль, август, сентябрь и октябрь.
-- Данные покрывают полный летний период и первые два месяца осени.
-- Данные можно использовать для предварительной оценки динамики спроса
-- перед началом зимнего сезона и выявления категорий мероприятий, городов,
-- устройств и пользовательских сегментов, которые показывают рост к октябрю.

-------------------------------------------------------------------------------------------------------------------------------------

-- 1.6. Проверка категориальных полей
-- Цель: изучить значения категориальных признаков и выявить возможные некорректные категории.
--
-- Проверяем:
-- device_type_canonical
-- currency_code
-- service_name
-- event_type_main
-- event_type_description
-- organizers
-- age_limit

-- 1.6.1. Распределение заказов по устройствам
SELECT 
	device_type_canonical, 
	count(DISTINCT order_id) AS total_orders
FROM purchases p 
GROUP BY device_type_canonical
ORDER BY total_orders DESC;

-- Вывод:
-- Основная часть заказов приходится на mobile — 232 679 заказов.
-- На втором месте desktop — 58 170 заказов.
-- Остальные категории встречаются редко.


-- 1.6.2. Распределение заказов по валютам
SELECT 
	currency_code, 
	count(DISTINCT order_id) AS total_orders
FROM purchases p 
GROUP BY currency_code
ORDER BY total_orders DESC;

-- Вывод:
-- В данных представлены две валюты: rub и kzt.
-- Большинство заказов оформлено в рублях — 286 961 заказ.
-- При дальнейшем анализе денежных метрик нужно учитывать наличие двух валют.


-- 1.6.3. Распределение заказов по сервисам
SELECT 
	service_name, 
	count(DISTINCT order_id) AS total_orders
FROM purchases p 
GROUP BY service_name
ORDER BY total_orders DESC;

-- Вывод:
-- В данных представлено много сервисов оформления заказов.
-- Лидируют "Билеты без проблем", "Лови билет!", "Билеты в руки", "Мой билет" и "Облачко".


-- 1.6.4. Распределение заказов по основным типам мероприятий
SELECT 
	e.event_type_main,
	count(DISTINCT p.order_id) AS total_orders
FROM purchases p 
JOIN events e  
	ON p.event_id = e.event_id
GROUP BY e.event_type_main
ORDER BY total_orders DESC;

-- Вывод:
-- По основным типам мероприятий лидируют концерты — 115 634 заказа.
-- На втором месте театр — 67 744 заказа.
-- Также значительную долю занимает категория "другое" — 66 109 заказов.
-- Минимальное количество заказов приходится на фильмы — 238 заказов.
-- Следовательно, концерты и театральные мероприятия являются основными направлениями спроса.



-- 1.6.5. Распределение заказов по детальным типам мероприятий
SELECT 
	e.event_type_description,
	count(DISTINCT p.order_id) AS total_orders
FROM purchases p 
JOIN events e  
	ON p.event_id = e.event_id
GROUP BY e.event_type_description
ORDER BY total_orders DESC;

-- Вывод:
-- По детальным типам мероприятий лидируют концерт — 112 405 заказов,
-- событие — 58 813 заказов и спектакль — 50 937 заказов.
-- В данных также есть редкие категории с единичными заказами.


-- 1.6.6. Распределение заказов по возрастным ограничениям
SELECT 
    age_limit,
    COUNT(DISTINCT order_id) AS total_orders
FROM purchases
GROUP BY age_limit
ORDER BY total_orders DESC;

-- Вывод:
-- Наибольшее количество заказов приходится на мероприятия с возрастным ограничением 16+:
-- 78 864 заказа.
-- Далее идут категории 12+ — 62 861 заказ и 0+ — 61 731 заказ.
-- Категории 6+ и 18+ также представлены, но имеют меньше заказов.
-- Самыми популярными возрастными категориями являются 16+, 12+ и 0+.


-- 1.6.7. Распределение заказов по организаторам
SELECT 
	e.organizers,
	count(DISTINCT p.order_id) AS total_orders
FROM purchases p 
JOIN events e  
	ON p.event_id = e.event_id
GROUP BY e.organizers
ORDER BY total_orders DESC
LIMIT 20;

-- Вывод:
-- Среди организаторов есть выраженные лидеры.
-- Больше всего заказов у организатора №1531 — 9 787.
-- Далее идут №2121, №4054, №4549 и №4837.


-- 1.6.8. Проверка разброса заказов по организаторам
WITH orders_by_organizer AS (
    SELECT 
        e.organizers,
        COUNT(DISTINCT p.order_id) AS total_orders
    FROM purchases AS p
    JOIN events AS e
        ON p.event_id = e.event_id
    GROUP BY e.organizers
)
SELECT
    COUNT(*) AS organizers_count,
    MIN(total_orders) AS min_orders_per_organizer,
    MAX(total_orders) AS max_orders_per_organizer,
    ROUND(AVG(total_orders)::numeric, 2) AS avg_orders_per_organizer
FROM orders_by_organizer;

-- Вывод:
-- Заказы по организаторам распределены неравномерно.
-- Всего в данных 4 294 организатора.
-- Минимальное количество заказов на организатора — 1, максимальное — 9 787,
-- среднее — 68.01 заказа.
-- Это означает, что у части организаторов спрос значительно выше среднего.

-- 1.6.9. Проверка возможных неявных дублей в названиях операторов
SELECT
    LOWER(
        REPLACE(
            REPLACE(
                REPLACE(TRIM(service_name), ' ', ''),
            '_', ''),
        '!', '')
    ) AS normalized_service_name,
    COUNT(DISTINCT service_name) AS original_names_count,
    STRING_AGG(DISTINCT service_name, ', ') AS original_names
FROM purchases
GROUP BY normalized_service_name
HAVING COUNT(DISTINCT service_name) > 1
ORDER BY original_names_count DESC;

-- Вывод:
-- Проверка возможных неявных дублей в названиях операторов по полю service_name
-- не выявила разных исходных названий, которые после нормализации становятся одинаковыми.
-- По проверенной логике неявные дубликаты в названиях операторов не обнаружены.


-- Общий вывод:
-- Категориальные поля содержат ожидаемые значения, явных некорректных категорий не обнаружено.
-- Основная часть заказов оформляется с мобильных устройств и в рублях.
-- При анализе денежных метрик нужно учитывать наличие заказов в двух валютах: rub и kzt.
-- По типам мероприятий основной спрос приходится на концерты и театр.
-- По возрастным ограничениям чаще всего встречаются категории 16+, 12+ и 0+.
-- Распределение заказов по организаторам неравномерное: среди 4 294 организаторов
-- максимальное количество заказов составляет 9 787, при среднем значении 68.01.
-- Поэтому организаторов с высоким количеством заказов стоит учитывать отдельно
-- при дальнейшем анализе спроса.
-- Проверка названий операторов по полю service_name после базовой нормализации
-- не выявила неявных дубликатов.
-------------------------------------------------------------------------------------------------------------------------------------

-- 1.7. Проверка числовых полей и аномалий
-- Цель: проверить числовые поля на нулевые, отрицательные и аномально большие значения.
--
-- Проверяем:
-- revenue
-- total
-- tickets_count


-- 1.7.1. Статистические показатели по revenue, total и tickets_count
SELECT 
    'revenue' AS field_name,
    MIN(revenue) AS min_value, 
    MAX(revenue) AS max_value, 
    ROUND(AVG(revenue)::numeric, 2) AS avg_value
FROM purchases AS p 
---
UNION ALL 
---
SELECT 
    'total' AS field_name,
    MIN(total) AS min_value,
    MAX(total) AS max_value,
    ROUND(AVG(total)::numeric, 2) AS avg_value
FROM purchases AS p 
---
UNION ALL 
---
SELECT 
    'tickets_count' AS field_name,
    MIN(tickets_count) AS min_value, 
    MAX(tickets_count) AS max_value, 
    ROUND(AVG(tickets_count), 2) AS avg_value
FROM purchases AS p;

-- Вывод:
-- В revenue и total обнаружены отрицательные минимальные значения.
-- В tickets_count минимальное значение равно 1, нулевых и отрицательных значений не видно.
-- Крупные максимальные значения revenue и total требуют дополнительной проверки.


-- 1.7.2. Проверка нулевых значений
SELECT
    SUM(CASE WHEN revenue = 0 THEN 1 ELSE 0 END) AS zero_revenue_count,
    SUM(CASE WHEN total = 0 THEN 1 ELSE 0 END) AS zero_total_count,
    SUM(CASE WHEN tickets_count = 0 THEN 1 ELSE 0 END) AS zero_tickets_count
FROM purchases;

-- Вывод:
-- В revenue и total есть нулевые значения.
-- В tickets_count нулевых значений нет.


-- 1.7.3. Проверка отрицательных значений
SELECT
    SUM(CASE WHEN revenue < 0 THEN 1 ELSE 0 END) AS negative_revenue_count,
    SUM(CASE WHEN total < 0 THEN 1 ELSE 0 END) AS negative_total_count,
    SUM(CASE WHEN tickets_count < 0 THEN 1 ELSE 0 END) AS negative_tickets_count
FROM purchases;

-- Вывод:
-- В revenue и total есть отрицательные значения.
-- В tickets_count отрицательных значений нет.


-- 1.7.4. Статистические показатели revenue в разрезе валют
SELECT 
    currency_code, 
    COUNT(DISTINCT order_id) AS total_orders,
    MIN(revenue) AS min_revenue, 
    MAX(revenue) AS max_revenue, 
    ROUND(AVG(revenue)::numeric, 2) AS avg_revenue,
    ROUND(STDDEV(revenue)::numeric, 2) AS std_revenue,
    SUM(CASE WHEN revenue = 0 THEN 1 ELSE 0 END) AS zero_revenue_count,
    SUM(CASE WHEN revenue < 0 THEN 1 ELSE 0 END) AS negative_revenue_count
FROM purchases
GROUP BY currency_code
ORDER BY total_orders DESC;

-- Вывод:
-- Revenue отличается по валютам: основная часть заказов оформлена в rub.
-- Отрицательные значения revenue обнаружены только в rub.
-- Нулевые значения есть в обеих валютах, но почти все они относятся к rub.



-- Общий вывод:
-- Числовые поля revenue, total и tickets_count были проверены на диапазон значений,
-- нулевые и отрицательные значения.
--
-- Поле tickets_count выглядит корректно: минимальное значение равно 1,
-- нулевых и отрицательных значений не обнаружено.
--
-- В денежных полях revenue и total обнаружены нулевые и отрицательные значения.
-- Это может быть связано с возвратами, отменами, бесплатными заказами,
-- промоакциями, корректировками или особенностями расчёта платежей.
--
-- В разрезе валют видно, что основные аномалии revenue сосредоточены
-- в рублёвых заказах: отрицательные значения revenue есть только в rub,
-- а почти все нулевые значения revenue также относятся к rub.
--
-- При дальнейшем расчёте выручки и среднего чека нужно явно фиксировать,
-- включаются ли нулевые и отрицательные заказы в анализ.
-- Также важно учитывать наличие двух валют и не смешивать денежные показатели
-- без приведения к единой валюте.

-------------------------------------------------------------------------------------------------------------------------------------


-- 1.8. Итоговый вывод по качеству данных
-- В ходе первичного знакомства была изучена структура базы данных,
-- проверены ключевые таблицы, уникальность идентификаторов, связи,
-- пропуски, период данных, категориальные и числовые поля.
--
-- Основная таблица для анализа — purchases.
-- Для детализации заказов используется таблица events,
-- а также справочники venues, city и regions.
--
-- В основных таблицах purchases и events ключевые идентификаторы уникальны:
-- order_id — 292 034 уникальных значения, event_id — 22 484 уникальных значения.
-- Количество уникальных event_id больше, чем количество уникальных event_name_code:
-- 22 484 против 15 287. Это означает, что одному названию события
-- может соответствовать несколько разных событий.
-- В справочниках представлено 353 уникальных города и 81 уникальный регион.
--
-- Проверка связей между таблицами показала, что ключевые связи корректны:
-- purchases -> events, events -> venues, events -> city, city -> regions.
-- Несвязанных записей не обнаружено, поэтому при объединении таблиц
-- по указанным ключам потери данных не ожидается.
--
-- В ключевых аналитических полях таблиц purchases и events пропуски не обнаружены.
-- Это позволяет использовать данные для анализа заказов, пользователей,
-- мероприятий, устройств, городов, площадок и организаторов.
--
-- Данные охватывают период с 1 июня по 31 октября 2024 года.
-- Внутри периода представлены все месяцы: июнь, июль, август, сентябрь и октябрь.
-- Такой период подходит для предварительной оценки летне-осенней динамики спроса
-- перед подготовкой к зимнему сезону.
--
-- Категориальные поля содержат ожидаемые значения, явных некорректных категорий
-- не обнаружено. Основная часть заказов оформляется с мобильных устройств
-- и в рублях. По типам мероприятий лидируют концерты и театр.
-- По возрастным ограничениям чаще всего встречаются категории 16+, 12+ и 0+.
-- Проверка названий операторов по полю service_name после базовой нормализации
-- не выявила неявных дубликатов.
--
-- Распределение заказов по организаторам неравномерное:
-- среди 4 294 организаторов максимальное количество заказов составляет 9 787,
-- при среднем значении 68.01. Поэтому организаторов с высоким количеством
-- заказов стоит учитывать отдельно при дальнейшем анализе спроса.
--
-- Числовые поля revenue, total и tickets_count были проверены на диапазон значений,
-- нулевые и отрицательные значения.
-- Поле tickets_count выглядит корректно: минимальное значение равно 1,
-- нулевых и отрицательных значений не обнаружено.
-- В денежных полях revenue и total есть нулевые и отрицательные значения.
-- Эти записи могут быть связаны с возвратами, отменами, бесплатными заказами,
-- промоакциями или корректировками.
--
-- Revenue была дополнительно изучена в разрезе валют.
-- Основная часть заказов оформлена в rub — 286 961 заказ.
-- В kzt оформлено 5 073 заказа.
-- Отрицательные значения revenue обнаружены только в rub.
-- Нулевые значения revenue есть в обеих валютах, но почти все они относятся к rub.
-- Максимальное значение revenue в rub составляет 81 174.54, что значительно выше
-- среднего значения 547.57 и стандартного отклонения 870.62.
--
-- По результатам проверки данные можно использовать для дальнейшего анализа.
--
-- Основные ограничения данных:
-- 1. В данных присутствуют две валюты: rub и kzt, поэтому денежные метрики
--    нужно анализировать с учётом валюты или приводить к единой валюте.
-- 2. В revenue и total есть нулевые и отрицательные значения, поэтому при расчёте
--    выручки и среднего чека нужно явно фиксировать, включаются ли такие заказы.
-- 3. Данные заканчиваются 31 октября 2024 года, поэтому анализ отражает динамику
--    до начала ноября, а не фактический спрос зимнего праздничного периода.
-- 4. Категория "другое" занимает значительную долю среди типов мероприятий,
--    поэтому её нужно учитывать отдельно при интерпретации структуры спроса.
-- 5. Распределение заказов по организаторам неравномерное, поэтому топ-организаторы
--    могут заметно влиять на общую картину спроса.