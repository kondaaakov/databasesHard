DROP DATABASE IF EXISTS shop;
CREATE DATABASE shop;
USE shop;

-- ЗАДАНИЕ ПО ТЕМЕ "ОПЕРАТОРЫ, ФИЛЬТРАЦИЯ, СОРТИРОВКА И ОГРАНИЧЕНИЕ --
/* Задание №1
Пусть в таблице users поля created_at и updated_at оказались незаполненными. Заполните их текущими датой и временем.
*/
INSERT INTO users (created_at, updated_at) VALUES (NOW(), NOW());

/* Задание №2
Таблица users была неудачно спроектирована. 
Записи created_at и updated_at были заданы типом VARCHAR и в них долгое время помещались значения в формате 20.10.2017 8:10. 
Необходимо преобразовать поля к типу DATETIME, сохранив введённые ранее значения. 
*/
UPDATE users set created_at=STR_TO_DATE(created_at, '%d.%m.%Y %H:%i'), updated_at=STR_TO_DATE(updated_at, '%d.%m.%Y %H:%i');
ALTER TABLE users MODIFY created_at DATETIME, MODIFY updated_at DATETIME;

/* Задание №3
В таблице складских запасов storehouses_products в поле value могут встречаться самые разные цифры: 
0, если товар закончился и выше нуля, если на складе имеются запасы. 
Необходимо отсортировать записи таким образом, чтобы они выводились в порядке увеличения значения value. 
Однако нулевые запасы должны выводиться в конце, после всех записей.
*/
SELECT VALUE FROM (SELECT VALUE, IF(VALUE=0, ~0, VALUE) AS zeroes FROM storehouses_products ORDER BY zeroes) AS agg;

/* Задание №4
Из таблицы users необходимо извлечь пользователей, родившихся в августе и мае. Месяцы заданы в виде списка английских названий (may, august)
*/
SELECT * FROM users WHERE DATE_FORMAT(birthday_at, '%M') in ('may', 'august');

/* Задание №5
Из таблицы catalogs извлекаются записи при помощи запроса. SELECT * FROM catalogs WHERE id IN (5, 1, 2); 
Отсортируйте записи в порядке, заданном в списке IN.
*/
SELECT * FROM catalogs WHERE id IN (5, 1, 2) ORDER BY FIELD(id, 5, 1, 2);

-- ЗАДАНИЕ ПО ТЕМЕ "АГРЕГАЦИЯ ДАННЫХ" --
/* Задание №1
Подсчитайте средний возраст пользователей в таблице users.
*/
SELECT AVG(age) FROM (SELECT YEAR(CURRENT_TIMESTAMP) - YEAR(birthday_at) as age FROM users) AS avg_age;

/* Задание №2
Подсчитайте количество дней рождения, которые приходятся на каждый из дней недели. 
Следует учесть, что необходимы дни недели текущего года, а не года рождения
*/
SELECT COUNT(*) AS stats 
FROM (
	SELECT DAYOFWEEK(
		CONCAT(YEAR(NOW()), '-', MONTH(birthday_at), '-', DAYOFMONTH(birthday_at))
			) AS nubmer_of_day FROM users
    )
    AS stats WHERE nubmer_of_day=1;
    -- ...тут nubmer_of_day является номером дня недели. от 1 до 7.

/* Задание №3
Подсчитайте произведение чисел в столбце таблицы.
*/
SELECT EXP(sum(log(price))) FROM products;
	-- ...посчитал произведение чисел из столбца price таблицы продуктов.
