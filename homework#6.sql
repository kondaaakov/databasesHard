USE vk;

/* Задание №1
Пусть задан некоторый пользователь. Из всех друзей этого пользователя найдите человека, который больше всех общался с нашим пользователем.
*/
SELECT count(*) mess, friend FROM 
	(SELECT body, to_user_id AS friend FROM messages WHERE from_user_id = 1
	 UNION
	 SELECT body,from_user_id AS friend FROM messages WHERE to_user_id = 1) as history
GROUP BY friend
ORDER BY mess DESC
LIMIT 1;

/* Задание №2
Подсчитать общее количество лайков, которые получили пользователи младше 10 лет.
*/

SELECT COUNT(id) FROM likes 
	WHERE user_id = 
		(SELECT user_id FROM profiles WHERE YEAR(birthday) > 2011 AND user_id = likes.user_id);


/* Задание №3
Определить кто больше поставил лайков (всего): мужчины или женщины.
*/

SELECT IF(
	(SELECT COUNT(id) FROM LIKES WHERE user_id IN (
		SELECT user_id FROM profiles WHERE gender="m")
	) 
	> 
	(SELECT COUNT(id) FROM LIKES WHERE user_id IN (
		SELECT user_id FROM profiles WHERE gender="f")
	), 
   'male', 'female');