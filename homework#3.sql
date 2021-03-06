DROP DATABASE IF EXISTS vk;
CREATE DATABASE vk;
USE vk;

DROP TABLE IF EXISTS users;
CREATE TABLE users (
	id SERIAL PRIMARY KEY, -- SERIAL = BIGINT UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE
    firstname VARCHAR(100),
    lastname VARCHAR(100) COMMENT 'Фамилия', -- COMMENT на случай, если имя неочевидное
    email VARCHAR(100) UNIQUE,
    password_hash varchar(100),
    phone BIGINT,
    is_deleted bit default 0,
    -- INDEX users_phone_idx(phone), -- помним: как выбирать индексы
    INDEX users_firstname_lastname_idx(firstname, lastname)
);

DROP TABLE IF EXISTS `profiles`;
CREATE TABLE `profiles` (
	user_id SERIAL PRIMARY KEY,
    gender CHAR(1),
    birthday DATE,
	photo_id BIGINT UNSIGNED NULL,
    created_at DATETIME DEFAULT NOW(),
    hometown VARCHAR(100),
    
    FOREIGN KEY (photo_id) REFERENCES media(id)
);

ALTER TABLE `profiles` ADD CONSTRAINT fk_user_id
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE CASCADE ON DELETE CASCADE;

DROP TABLE IF EXISTS messages;
CREATE TABLE messages (
	id SERIAL PRIMARY KEY,
	from_user_id BIGINT UNSIGNED NOT NULL,
    to_user_id BIGINT UNSIGNED NOT NULL,
    body TEXT,
    created_at DATETIME DEFAULT NOW(), -- можно будет даже не упоминать это поле при вставке

    FOREIGN KEY (from_user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (to_user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE
);

DROP TABLE IF EXISTS friend_requests;
CREATE TABLE friend_requests (
	-- id SERIAL PRIMARY KEY, -- изменили на составной ключ (initiator_user_id, target_user_id)
	initiator_user_id BIGINT UNSIGNED NOT NULL,
    target_user_id BIGINT UNSIGNED NOT NULL,
    -- `status` TINYINT UNSIGNED,
    `status` ENUM('requested', 'approved', 'declined', 'unfriended'),
    -- `status` TINYINT UNSIGNED, -- в этом случае в коде хранили бы цифирный enum (0, 1, 2, 3...)
	requested_at DATETIME DEFAULT NOW(),
	updated_at DATETIME on update now(),
	
    PRIMARY KEY (initiator_user_id, target_user_id),
    FOREIGN KEY (initiator_user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (target_user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE
);

DROP TABLE IF EXISTS communities;
CREATE TABLE communities(
	id SERIAL PRIMARY KEY,
	name VARCHAR(150),
	admin_user_id BIGINT UNSIGNED,

	INDEX communities_name_idx(name),
	FOREIGN KEY (admin_user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE set null
);

DROP TABLE IF EXISTS users_communities;
CREATE TABLE users_communities(
	user_id BIGINT UNSIGNED NOT NULL,
	community_id BIGINT UNSIGNED NOT NULL,
  
	PRIMARY KEY (user_id, community_id), -- чтобы не было 2 записей о пользователе и сообществе
    FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (community_id) REFERENCES communities(id) ON UPDATE CASCADE ON DELETE CASCADE
);

DROP TABLE IF EXISTS media_types;
CREATE TABLE media_types(
	id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    created_at DATETIME DEFAULT NOW(),
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP

    -- записей мало, поэтому индекс будет лишним (замедлит работу)!
);

DROP TABLE IF EXISTS media;
CREATE TABLE media(
	id SERIAL PRIMARY KEY,
    media_type_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
  	body text,
    filename VARCHAR(255),
    `size` INT,
	metadata JSON,
    created_at DATETIME DEFAULT NOW(),
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (media_type_id) REFERENCES media_types(id) ON UPDATE CASCADE ON DELETE CASCADE
);

DROP TABLE IF EXISTS likes;
CREATE TABLE likes(
	id SERIAL PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    media_id BIGINT UNSIGNED NOT NULL,
    created_at DATETIME DEFAULT NOW(),

    -- PRIMARY KEY (user_id, media_id) – можно было и так вместо id в качестве PK
  	-- слишком увлекаться индексами тоже опасно, рациональнее их добавлять по мере необходимости (напр., провисают по времени какие-то запросы)  

/* намеренно забыли, чтобы позднее увидеть их отсутствие в ER-диаграмме*/
    FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (media_id) REFERENCES media(id) ON UPDATE CASCADE ON DELETE CASCADE

);

DROP TABLE IF EXISTS `photo_albums`;
CREATE TABLE `photo_albums` (
	`id` SERIAL,
	`name` varchar(255) DEFAULT NULL,
    `user_id` BIGINT UNSIGNED DEFAULT NULL,

    FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE set NULL,
  	PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `photos`;
CREATE TABLE `photos` (
	id SERIAL PRIMARY KEY,
	`album_id` BIGINT unsigned NOT NULL,
	`media_id` BIGINT unsigned NOT NULL,

	FOREIGN KEY (album_id) REFERENCES photo_albums(id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (media_id) REFERENCES media(id) ON UPDATE CASCADE ON delete CASCADE
);

ALTER TABLE `profiles` ADD CONSTRAINT fk_photo_id
    FOREIGN KEY (photo_id) REFERENCES photos(id)
    ON UPDATE CASCADE ON DELETE set NULL;

-- Таблца для постов. Тут пока не привязывается ни к какой сущности в виде пользователя или сообщества.
DROP TABLE IF EXISTS posts;
CREATE TABLE posts (
	id SERIAL PRIMARY KEY,
	`media_id` BIGINT UNSIGNED NOT NULL,
	body TEXT,
	
    FOREIGN KEY (media_id) REFERENCES media(id) ON UPDATE CASCADE ON delete CASCADE
);

-- Далее таблица постов юзеров. Привязка к ID поста и ID юзера.
DROP TABLE IF EXISTS `users_posts`;
CREATE TABLE `users_posts` (
	post_id SERIAL PRIMARY KEY,
	`user_id` BIGINT UNSIGNED NOT NULL,
	
	FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (post_id) REFERENCES posts(id) ON UPDATE CASCADE ON DELETE CASCADE
);

   

DROP TABLE IF EXISTS `communities_posts`;
CREATE TABLE `communities_posts` (
	post_id SERIAL PRIMARY KEY,
	`community_id` BIGINT UNSIGNED NOT NULL,
	
	FOREIGN KEY (community_id) REFERENCES communities(id) ON UPDATE CASCADE ON DELETE CASCADE
);

ALTER TABLE `communities_posts` ADD CONSTRAINT cp_post_id
    FOREIGN KEY (post_id) REFERENCES posts(id)
    ON UPDATE CASCADE ON DELETE CASCADE;

INSERT INTO `users` VALUES (1,'Cloyd','Carter','roselyn11@example.org','bada109c909f9ae7103dad01c78f6c431c322819',330645,'\0'),(2,'Lauretta','Shields','morissette.margarete@example.net','e5a514803b7007aecf30c24a38b65028e651dad3',590587,'\0'),(3,'Marianne','Hodkiewicz','sipes.juanita@example.com','9f67f5aedeb5dee325a3bbb8d9b4ac1432a36146',85,'\0'),(4,'Blaze','Rowe','micaela88@example.org','bbb43f42d61a77612359b769b352ebf10805b226',0,'\0'),(5,'Hermann','Harris','kian.blanda@example.com','dee50ad91b69ee326f215fba0ec73ecf261b0843',0,'\0'),(6,'Damian','Huels','wintheiser.olaf@example.com','4d0df611360525bea7d320bc18e4c3ab34ccfc30',144170,'\0'),(7,'Jarrod','Brakus','tlarson@example.org','1dcfa2b8eacbcc6d0647e2ae1fbec421339c44c5',198080,'\0'),(8,'Fidel','Lebsack','fkoepp@example.org','47dc01b173483c1d2bdc913f357f845489d24e61',731,''),(9,'Destany','Cartwright','turcotte.katharina@example.com','b292568af8c2d151da4afa4d41e75d4b1765fb3d',96,'\0'),(10,'Marisol','Langworth','bernhard.bosco@example.com','a4a5cfd4d17c9b6bb71412857520ad5acadfdb8a',7635571450,''),(11,'Ryder','Nitzsche','hcassin@example.com','9b4b4277d7f8f321553329ad48e5018af046bd01',528,'\0'),(12,'Karson','Cassin','considine.elmira@example.net','4789d3a9b036f45722845a8afcd153d0f31d9bf7',1,''),(13,'Baron','Hessel','kroberts@example.net','6195b784bc8a9bda62969fb7a828b18bc40dd1ea',45,'\0'),(14,'Clifford','Bartoletti','hortense.veum@example.net','48de11e90db063046ff7f2de4657731249dcdc2e',0,''),(15,'Rasheed','Braun','terry57@example.com','431bab84add37ffdde1c836db00f188c6265db23',874664,''),(16,'Irving','Roberts','kamron91@example.com','ba67762149f54ae76769272ecf8a264220e1fe7d',1,''),(17,'Daisy','Parisian','tblick@example.com','41cb1c147ca026c0a0e48217ccaa39507055daf9',303,''),(18,'Sabrina','Hayes','willard.prosacco@example.com','666caad999b183ed62f7106b103a9e984c14929e',0,'\0'),(19,'Jamil','Hirthe','marcellus56@example.com','ad9fff2ed806ea04a588fadb8e81751f8ed7c076',38,'\0'),(20,'Vincenzo','Casper','bwaters@example.org','a7a30a428133cd12e5e011acb3fd4381908cc0ee',76,'\0');
INSERT INTO `friend_requests` VALUES (1,1,'unfriended','1990-04-20 05:43:13','1996-08-10 00:16:36'),(2,2,'approved','2020-09-30 14:29:05','2007-08-18 21:02:01'),(3,3,'unfriended','1984-02-19 16:12:52','1995-09-06 10:55:57'),(4,4,'declined','1994-11-25 22:47:31','1998-05-13 14:11:17'),(5,5,'unfriended','2018-05-08 11:44:39','1986-11-02 18:48:45'),(6,6,'approved','1983-06-17 05:14:40','1989-04-26 06:22:01'),(7,7,'approved','2014-08-15 08:28:45','1981-09-29 08:18:17'),(8,8,'requested','1998-11-26 19:03:22','1979-08-08 21:50:33'),(9,9,'declined','1976-07-21 07:00:32','1996-12-18 16:35:24'),(10,10,'unfriended','1986-03-07 01:00:22','1987-11-05 03:23:34'),(11,11,'approved','2014-08-07 20:28:21','1985-07-04 20:08:05'),(12,12,'declined','1986-09-07 09:39:35','2014-08-07 17:06:38'),(13,13,'approved','1996-05-22 04:34:29','1991-04-24 16:49:52'),(14,14,'declined','1992-01-14 11:58:14','1972-01-28 01:27:26'),(15,15,'declined','1975-10-22 13:26:52','1980-07-29 05:45:35'),(16,16,'approved','1996-12-14 11:56:09','2015-11-26 01:10:14'),(17,17,'requested','1972-11-30 09:14:53','2017-04-23 04:37:32'),(18,18,'unfriended','1976-12-15 06:47:48','1975-02-07 11:56:22'),(19,19,'declined','2011-12-19 22:14:04','1981-06-07 15:58:00'),(20,20,'unfriended','1979-07-18 01:37:59','1974-07-29 10:35:11');
INSERT INTO `likes` VALUES (1,1,1,'2011-07-06 02:44:41'),(2,2,2,'1994-11-09 00:33:15'),(3,3,3,'1994-08-04 08:23:20'),(4,4,4,'1983-05-24 23:29:37'),(5,5,5,'2013-09-28 01:16:59'),(6,6,6,'1997-07-26 23:56:49'),(7,7,7,'1990-12-05 01:40:13'),(8,8,8,'1976-05-12 11:39:41'),(9,9,9,'1991-08-16 01:58:23'),(10,10,10,'1999-10-10 06:52:50'),(11,11,11,'1971-12-05 11:14:50'),(12,12,12,'1999-03-29 05:23:28'),(13,13,13,'2007-04-25 07:24:57'),(14,14,14,'2007-09-23 17:17:32'),(15,15,15,'2019-06-15 04:51:58'),(16,16,16,'1977-10-14 20:55:54'),(17,17,17,'1978-11-22 04:00:05'),(18,18,18,'1980-04-19 09:09:22'),(19,19,19,'1979-08-25 14:31:58'),(20,20,20,'1989-12-20 16:26:39');
INSERT INTO `messages` VALUES (1,1,1,'Enim perferendis autem est nobis. Quaerat illum unde in odio. Ipsum suscipit repudiandae doloremque et. Dicta molestiae cupiditate expedita ad quam non dolores. Architecto laudantium sequi in illo nobis facere.','1983-05-28 19:43:21'),(2,2,2,'Architecto facere qui quam sed vero. Eius quas recusandae aut ut. Dicta incidunt dolorem enim numquam. Optio quibusdam ducimus ea inventore.','1989-12-31 17:21:24'),(3,3,3,'Deleniti quos rerum occaecati maiores odit veritatis. Laborum doloribus aut eum nostrum. Autem ut et adipisci aut nulla accusamus. Cupiditate deserunt veniam nobis labore.','2017-09-11 20:29:11'),(4,4,4,'Veniam quia laborum sed sapiente. Minus occaecati id molestiae placeat cupiditate sapiente possimus.','1986-10-23 12:03:19'),(5,5,5,'Omnis dolores nisi sed reprehenderit magnam animi. Pariatur aliquam et quis. Voluptas a velit omnis.','2007-05-02 17:20:40'),(6,6,6,'Quidem voluptas dolores dolor dolores voluptatem sit eos maiores. Cumque ab voluptatem quas quia molestias quidem. Omnis voluptatem non omnis fugit rerum. Unde necessitatibus saepe fuga quis.','1996-08-17 00:01:02'),(7,7,7,'Rerum illo officiis dolores harum. Minima sequi occaecati consectetur.','2012-06-25 07:27:13'),(8,8,8,'In ipsam quis perspiciatis eos labore eum a ex. Consequatur qui ea necessitatibus reprehenderit minus consequatur officiis. Dolore excepturi rerum esse possimus. Excepturi omnis voluptatum facilis ipsa quos perspiciatis.','1994-06-12 09:14:07'),(9,9,9,'Laborum qui est et. Voluptas deserunt occaecati odit neque et voluptates tenetur. Id atque cumque repellendus recusandae non numquam unde. Provident itaque et aut aut.','2015-08-06 16:51:59'),(10,10,10,'Velit veniam molestiae id minus. Eaque laboriosam nostrum accusantium autem delectus. Id consequatur veniam amet ab illum et. Vero iure adipisci quo ad sed.','1983-05-16 01:06:52'),(11,11,11,'Placeat reiciendis voluptas officia rerum impedit beatae impedit rerum. Dolorem sequi vel minus et minima mollitia.','2008-12-03 19:19:19'),(12,12,12,'Unde consequuntur qui corrupti unde unde quia ad. Facilis necessitatibus doloribus omnis perspiciatis tempore veritatis eum. Vel fugit ea velit saepe natus ut perspiciatis. Libero laboriosam ipsam eius in vitae in rerum.','2012-11-15 14:55:05'),(13,13,13,'Qui culpa quo totam totam eligendi omnis. Officia sed voluptatem reprehenderit facere. Quidem explicabo dolorem similique quos sint omnis. Magni neque tempora aut provident sunt aperiam.','2015-01-19 05:04:55'),(14,14,14,'Labore dignissimos asperiores fugiat quam. Accusantium qui et aut. Autem cupiditate explicabo autem officia aut. Et aut qui tempore sit perspiciatis molestias. Maxime dolorem voluptas reprehenderit.','2001-08-09 07:20:54'),(15,15,15,'Ut ipsa quas ex amet. Sint est assumenda ut ad voluptates hic. Consequatur dignissimos consectetur molestias beatae dolores ea et.','2006-03-02 16:40:06'),(16,16,16,'Earum aut nostrum sed ut. Ut est reiciendis quasi a. Accusantium quas sapiente officia omnis nobis alias qui. Perspiciatis nobis soluta vel non facere rerum.','2004-03-22 04:17:46'),(17,17,17,'Omnis qui sed vel ratione. Harum et exercitationem natus. Fugiat aut molestiae aut modi. Dolore est saepe molestiae in consequatur.','1976-12-26 12:53:56'),(18,18,18,'Praesentium possimus non rerum quasi et voluptate ab. Repellat excepturi corporis quis ea nobis sit.','2002-06-10 10:23:37'),(19,19,19,'Quis veniam voluptas repellat numquam eaque in perferendis doloribus. Maxime ut molestias a velit in odit omnis.','1975-09-30 11:30:41'),(20,20,20,'Adipisci possimus nemo dolor cupiditate velit cupiditate. Consequatur esse beatae consequatur molestiae ratione. Voluptas sed aut mollitia tempora repellat quae totam. Delectus vel ullam unde dolorem architecto itaque rerum.','2008-11-30 19:37:12');

INSERT INTO `communities` VALUES (1,'cum',1),(2,'ut',2),(3,'debitis',3),(4,'nemo',4),(5,'sequi',5),(6,'aut',6),(7,'voluptas',7),(8,'tenetur',8),(9,'occaecati',9),(10,'itaque',10),(11,'sed',11),(12,'aliquid',12),(13,'ducimus',13),(14,'deserunt',14),(15,'earum',15),(16,'qui',16),(17,'in',17),(18,'possimus',18),(19,'et',19),(20,'labore',20),(21,'ratione',1),(22,'consequatur',2),(23,'qui',3),(24,'cumque',4),(25,'repellat',5),(26,'animi',6),(27,'necessitatibus',7),(28,'facere',8),(29,'facilis',9),(30,'officiis',10),(31,'saepe',11),(32,'quas',12),(33,'at',13),(34,'et',14),(35,'in',15),(36,'aut',16),(37,'vitae',17),(38,'omnis',18),(39,'non',19),(40,'doloremque',20),(41,'quia',1),(42,'nemo',2),(43,'necessitatibus',3),(44,'quasi',4),(45,'odit',5),(46,'ex',6),(47,'eum',7),(48,'a',8),(49,'ipsum',9),(50,'explicabo',10),(51,'corrupti',11),(52,'aspernatur',12),(53,'aut',13),(54,'expedita',14),(55,'quis',15),(56,'et',16),(57,'atque',17),(58,'fugit',18),(59,'ex',19),(60,'aut',20),(61,'enim',1),(62,'deserunt',2),(63,'distinctio',3),(64,'consequatur',4),(65,'culpa',5),(66,'odit',6),(67,'beatae',7),(68,'sit',8),(69,'provident',9),(70,'in',10),(71,'temporibus',11),(72,'quidem',12),(73,'illum',13),(74,'ipsum',14),(75,'voluptatum',15),(76,'veniam',16),(77,'culpa',17),(78,'alias',18),(79,'sunt',19),(80,'et',20),(81,'unde',1),(82,'sunt',2),(83,'illum',3),(84,'nemo',4),(85,'maxime',5),(86,'esse',6),(87,'mollitia',7),(88,'quo',8),(89,'vel',9),(90,'possimus',10),(91,'reiciendis',11),(92,'est',12),(93,'soluta',13),(94,'quod',14),(95,'aut',15),(96,'aspernatur',16),(97,'corporis',17),(98,'aliquam',18),(99,'libero',19),(100,'et',20);
INSERT INTO `users_communities` VALUES (1,1),(2,2),(3,3),(4,4),(5,5),(6,6),(7,7),(8,8),(9,9),(10,10);

INSERT INTO `media_types` VALUES (1,'ex','1992-09-20 13:21:42','1974-11-18 16:56:42'),(2,'fugiat','2011-01-19 11:19:26','2001-11-09 12:00:57'),(3,'culpa','1990-05-10 15:13:22','1970-10-07 15:49:20'),(4,'tempora','1975-11-28 11:31:22','1996-07-07 18:52:55'),(5,'commodi','2018-10-05 12:21:49','2009-10-19 19:52:25'),(6,'ex','1987-12-23 12:33:22','1989-02-04 11:32:35'),(7,'distinctio','1994-01-22 03:22:23','2000-05-12 23:55:37'),(8,'est','1989-06-07 17:56:01','1998-02-25 10:59:12'),(9,'neque','2013-09-01 21:45:12','1973-09-19 18:33:08'),(10,'facere','2000-12-16 08:16:42','1978-08-05 00:18:39');
INSERT INTO `media` VALUES (1,1,1,'Ipsum id illo natus minima iusto consequatur nostrum. Alias numquam aspernatur mollitia ut ratione.','minus',4473,NULL,'2006-01-06 04:28:46','1997-07-27 04:36:04'),(2,2,2,'Optio voluptatem quisquam veniam eveniet doloremque necessitatibus molestiae. Asperiores aut voluptatum eligendi inventore placeat id. Consequatur commodi asperiores voluptatibus sunt quidem cupiditate labore. Et quis ducimus aut natus.','deleniti',1487211,NULL,'2016-08-04 16:50:03','1974-05-30 11:27:47'),(3,3,3,'Dolore porro quam aut non maxime sunt vel enim. Qui debitis nihil ut. Asperiores doloremque voluptatem repellat ad sequi architecto error est.','rerum',85539740,NULL,'1996-04-28 11:29:40','2013-07-11 17:05:10'),(4,4,4,'Aut qui iure quia doloribus explicabo aut. Recusandae qui facilis voluptatem maiores nihil corporis quo aut. Exercitationem cum ex ex ab sint quia quos.','magni',554874737,NULL,'1973-07-09 03:11:02','2009-10-05 18:39:26'),(5,5,5,'Est repellendus quod voluptates natus sed eligendi omnis. Quia facere illo animi labore eius quia accusantium.','voluptate',5418,NULL,'2003-03-15 07:53:24','2000-06-20 21:04:10'),(6,6,6,'Totam veniam dolor qui id odio commodi aspernatur. Tempora officia libero adipisci. Et odio dolore provident nihil totam adipisci. Id temporibus voluptate illum adipisci dicta aut et aliquid.','et',989180,NULL,'1987-03-06 05:24:00','1993-06-16 20:38:06'),(7,7,7,'Fugit natus iusto qui fugit. Sit perferendis rerum ut facere. Ab non impedit similique assumenda laboriosam rerum atque ullam.','magnam',9,NULL,'2007-04-13 03:37:10','1991-08-07 03:38:54'),(8,8,8,'Molestiae voluptatem fugiat magnam ex. Qui deleniti rem autem aut ullam dolore qui. Pariatur aperiam animi temporibus voluptas dolores officiis et est. Quia optio eius quos similique maxime voluptas nihil accusamus.','minus',799206,NULL,'1992-01-07 09:17:22','1990-06-04 21:07:50'),(9,9,9,'Delectus maxime vero asperiores eaque quibusdam eveniet. Fugiat odio ratione possimus asperiores. Optio et sunt sunt ipsum unde et esse cum. Odio est voluptatem tenetur similique nostrum quisquam.','corporis',92,NULL,'2000-09-06 20:24:35','2015-10-29 18:14:33'),(10,10,10,'Aperiam aut consequatur nulla eum non et architecto. Esse eos aut vitae cupiditate. Mollitia debitis quaerat aut quo nostrum in quos. Dolor labore omnis enim.','ad',7071,NULL,'1973-10-17 08:25:41','2004-11-07 10:42:19'),(11,1,11,'Sit sapiente voluptatum quae dignissimos consectetur. Quis recusandae iste officia rerum.','inventore',993,NULL,'2005-01-17 11:21:51','1978-11-15 23:23:05'),(12,2,12,'Nesciunt ex recusandae quas. Dolorem nisi voluptatem et sed est.','ea',89942,NULL,'1997-09-02 03:44:25','1987-04-15 03:08:04'),(13,3,13,'Repellat qui corrupti ipsam officiis blanditiis veritatis. Et ex quia eius quia illum sunt.','ex',7089483,NULL,'1988-07-20 18:12:20','2008-08-29 23:43:04'),(14,4,14,'Labore sint minima et velit sit. Enim porro similique iure tempora. Qui sit rerum provident omnis minus.','debitis',982662293,NULL,'1971-07-31 01:53:02','1999-11-29 21:07:39'),(15,5,15,'Sapiente sint quo eum ut aspernatur voluptate iure. Possimus soluta ipsa consequatur vitae et voluptas harum sunt. Error ullam et accusamus ab aut et quam.','ipsam',354,NULL,'1996-08-18 12:55:02','1982-10-21 21:47:51'),(16,6,16,'Harum repellat quia odio maiores vitae aliquam dolorem. Sequi voluptates facere quidem hic est aut dolor officiis. Aut harum sed hic consequatur.','earum',141821014,NULL,'1998-07-13 06:41:43','2008-11-01 16:12:09'),(17,7,17,'Non ipsam molestiae qui magnam delectus enim. Odit deserunt facere omnis laudantium.','repellat',500578901,NULL,'2012-09-01 18:05:52','1990-01-14 22:16:33'),(18,8,18,'Perspiciatis soluta et illum assumenda praesentium. Illum assumenda placeat nam voluptate est id molestiae. Perferendis assumenda sapiente perferendis consequatur.','sed',56,NULL,'1975-07-05 08:52:56','1997-10-23 14:53:22'),(19,9,19,'Quidem et aut distinctio asperiores. Tempora libero facere voluptatem suscipit numquam incidunt totam. Temporibus deserunt ad consectetur molestias repudiandae provident.','officiis',1342892,NULL,'1982-12-03 04:21:48','2011-12-21 13:59:23'),(20,10,20,'Corrupti itaque ex et doloribus excepturi ratione odit sed. Officia sit vero et alias sed. Numquam molestias architecto labore modi eum error possimus fugiat. Voluptatem ducimus delectus et voluptatem.','illum',54,NULL,'2015-03-07 18:03:26','1995-01-27 16:47:10');
INSERT INTO `profiles` VALUES (1,'D','1990-12-09',1,'1980-05-18 11:44:45','East'),(2,'D','2009-11-26',2,'2003-09-20 20:54:10','East'),(3,'D','2020-09-14',3,'1981-04-26 08:33:47','South'),(4,'D','1985-09-04',4,'1982-07-18 18:06:27','Port'),(5,'D','1997-12-13',5,'2015-04-15 03:30:14','East'),(6,'M','2013-12-07',6,'1977-07-25 05:09:18','South'),(7,'P','2018-03-26',7,'2011-03-21 15:13:49','West'),(8,'D','1994-09-16',8,'2019-09-03 13:03:40','North'),(9,'D','1978-09-29',9,'1993-05-19 21:51:54','Lake'),(10,'D','1988-04-04',10,'1977-04-05 12:51:11','Lake'),(11,'P','1970-07-30',11,'2005-10-30 05:27:43','Lake'),(12,'M','1987-07-31',12,'1975-07-16 04:11:43','West'),(13,'D','1978-09-26',13,'2000-07-06 15:37:45','East'),(14,'M','1997-01-18',14,'1987-08-14 08:33:52','South'),(15,'P','1980-10-31',15,'1978-12-17 22:22:34','New'),(16,'M','1977-05-08',16,'2007-04-11 14:15:41','South'),(17,'P','2018-04-12',17,'2002-07-29 21:17:57','North'),(18,'M','1978-01-18',18,'1999-06-20 21:29:22','East'),(19,'M','1976-05-24',19,'1977-02-10 02:06:13','South'),(20,'P','1974-02-13',20,'1989-02-15 04:24:12','West');

INSERT INTO `photo_albums` VALUES (1,'aliquam',1),(2,'ipsam',2),(3,'qui',3),(4,'dolores',4),(5,'voluptatem',5),(6,'qui',6),(7,'sed',7),(8,'nisi',8),(9,'dolor',9),(10,'non',10),(11,'aspernatur',11),(12,'nostrum',12),(13,'est',13),(14,'natus',14),(15,'sed',15),(16,'placeat',16),(17,'natus',17),(18,'quas',18),(19,'repellendus',19),(20,'et',20);
INSERT INTO `photos` VALUES (1,1,1),(2,2,2),(3,3,3),(4,4,4),(5,5,5),(6,6,6),(7,7,7),(8,8,8),(9,9,9),(10,10,10),(11,11,11),(12,12,12),(13,13,13),(14,14,14),(15,15,15),(16,16,16),(17,17,17),(18,18,18),(19,19,19),(20,20,20);

INSERT INTO `posts` VALUES (1,1,'Et molestiae molestiae vitae ea ullam quae ipsum voluptatem. Maxime beatae qui vero quae omnis. Non reprehenderit rerum commodi non repudiandae provident. Nam debitis quaerat impedit sed ipsam dolorem.'),(2,2,'Unde officiis est alias aut totam officia. Nostrum aspernatur perferendis ducimus unde beatae. Harum exercitationem sit voluptas velit ex.'),(3,3,'Vero et ut iusto. Voluptatem possimus et cumque distinctio quaerat voluptate repellendus. At omnis iure possimus eos accusantium quam. Porro voluptatem aut reprehenderit est et.'),(4,4,'Quam qui mollitia sit natus quis. Tempora vel harum deleniti vel illo rerum. Rem esse et quia commodi qui non quia quia.'),(5,5,'Eaque similique explicabo nulla voluptatem rerum. Sequi magni aut rerum doloribus ea iusto. Recusandae vero vero animi qui qui architecto. Nemo voluptatem ullam dolores aut.'),(6,6,'Necessitatibus aut harum ipsa. Deleniti dolor voluptatem et non aliquid. Quae non ab harum voluptas ut. Quod magnam delectus doloremque fuga.'),(7,7,'Rem sunt pariatur eum quia voluptas cum. Maiores beatae fugit id maiores iure dolores. Labore quo eos fugit incidunt maiores qui ut.'),(8,8,'Exercitationem sequi animi voluptas assumenda optio doloremque autem. Quis aut et molestiae quasi. Quia voluptas omnis odio tenetur ex ut.'),(9,9,'Iste eligendi aperiam quo quam nobis recusandae ex. Est ut aut maxime dolore nihil iusto adipisci. Veritatis praesentium repellendus deserunt magni fugiat animi voluptas. Aut nesciunt quo voluptas nihil maxime enim.'),(10,10,'Molestias id corrupti fuga officia. Suscipit doloribus earum rerum id placeat voluptatem. Voluptatum qui et blanditiis voluptas. Non facilis est velit tenetur vel et nihil.'),(11,11,'Nesciunt eos quam id neque reprehenderit. Quas quia illo et consequuntur error.'),(12,12,'Delectus ratione numquam explicabo qui sed sit odio. Porro fugit et eos omnis similique et. Consequatur reprehenderit et magni perspiciatis. Incidunt odio repellat rerum voluptate ea fugit aspernatur.'),(13,13,'Fugiat eos rerum corrupti non autem. Libero corrupti accusamus earum. Aut occaecati omnis et deleniti officiis. Repudiandae aut sequi quae eum eos.'),(14,14,'Incidunt maxime nam ut nisi voluptatum ipsa sed voluptatem. Rerum est beatae et animi fugiat inventore debitis. Fugiat accusantium aperiam corporis eveniet. Sed voluptatibus et nesciunt modi. At eveniet corrupti eaque voluptas.'),(15,15,'Illo ut veritatis velit neque sint. Esse nulla esse optio et cupiditate ex porro.'),(16,16,'Adipisci veritatis consequatur exercitationem nostrum. Et et quo sed tempora numquam ad. Atque saepe debitis et eveniet facere est ab. Itaque ducimus et ut placeat iste.'),(17,17,'Saepe molestiae enim sit est et pariatur. Iste molestias mollitia dicta dolore quia. Necessitatibus blanditiis eveniet ut repellendus omnis officiis commodi.'),(18,18,'Repudiandae ut id provident est omnis. Optio blanditiis recusandae qui rem. Doloribus ducimus ullam necessitatibus vel sequi voluptatum.'),(19,19,'Tenetur nostrum ea delectus. Autem dolore veniam aut ipsum. Quia porro non consequuntur et occaecati et temporibus. Aliquam animi modi quia aut inventore reprehenderit.'),(20,20,'Iure libero impedit est consectetur. Temporibus dolorem cupiditate reiciendis dolor aut. Qui unde voluptatem sint aliquam voluptatem.'),(21,1,'Perspiciatis non qui laudantium rerum omnis. Officia voluptate pariatur error earum illo vel molestiae.'),(22,2,'Minima temporibus porro ex recusandae. Iste quia placeat porro labore deleniti ab natus qui.'),(23,3,'Eius est qui voluptatem doloremque ad error nemo. Voluptatem sit voluptas voluptatem repellendus velit. Ut voluptatibus id reprehenderit sit sed dignissimos.'),(24,4,'Omnis repudiandae deleniti perferendis porro sunt ipsa. Et officiis placeat dolores ut tempore eum. Rerum omnis accusantium ipsam cupiditate est magni.'),(25,5,'Accusantium sint aut sit nam. Eius quia quo corrupti quia et nobis et. Adipisci velit adipisci facilis omnis facilis est.'),(26,6,'Deserunt molestiae omnis dolor est ipsum rerum. Sed illum autem ea velit aspernatur modi. Amet quae ipsum officia est id optio.'),(27,7,'Aut molestias error aut veniam veniam sit praesentium. Quaerat et ullam quia aut eos. Quia quo quod qui porro. Nostrum quos animi ut doloribus saepe placeat aut quas.'),(28,8,'Error officia quaerat officia harum. Delectus natus vel neque voluptates qui aut. Quis ullam tenetur optio ea excepturi laboriosam officiis repudiandae. Fuga et est omnis dolor ipsa.'),(29,9,'Exercitationem illo ullam a quis. Ducimus animi ullam omnis doloremque et. Est voluptas iure nostrum minus.'),(30,10,'Explicabo quos placeat assumenda cupiditate impedit quis unde. Laboriosam eveniet mollitia deserunt illo est voluptatibus accusantium. Vero et ratione molestias ratione illum cum eveniet.'),(31,11,'Dicta omnis nostrum ut alias. Architecto est qui est est earum. Incidunt earum voluptate nesciunt unde. Aut id autem reprehenderit aut non non minus.'),(32,12,'Fugiat saepe ut facere et eligendi commodi tempore fugit. Sit non ab excepturi expedita esse eius quidem. Eos voluptatum inventore iure alias quas officia.'),(33,13,'Aut aut vitae nam nam est aut. Quia laboriosam consequatur dolore dolores ullam dolores asperiores et. Est facere quasi illo. Quo rerum ea id voluptatibus eligendi eligendi suscipit.'),(34,14,'Eius eveniet quibusdam ab repellat. Dolorem ea ut aut itaque autem deleniti repudiandae. Eum ab consequatur et ex veniam nemo laboriosam. Quia esse officia reprehenderit sed.'),(35,15,'Et dolorum amet nam et ullam omnis ut. Rem eum expedita dolor quasi. Asperiores illum fuga iste a ex aspernatur dolorem.'),(36,16,'Maiores autem enim atque accusamus. Et porro reprehenderit reprehenderit debitis quas ipsum aut. Adipisci sunt ratione delectus ut beatae nam. Repellendus sapiente et ipsam labore hic repellendus.'),(37,17,'Sit quas ut odit repudiandae. Nihil vero iure fugiat dolores voluptatem dolores pariatur qui. Laudantium dolore quia ipsam accusantium. Perferendis nostrum repudiandae libero sit modi dolorem sunt.'),(38,18,'Facere soluta quod consequuntur eius quas. Voluptates dolorem perspiciatis quo dolorum temporibus. Ipsam consectetur ab quibusdam doloribus consequatur nulla consequuntur.'),(39,19,'Possimus expedita et voluptas. Quae reprehenderit iste aliquam corporis qui totam.'),(40,20,'Dolorem dignissimos et soluta architecto repudiandae molestiae veritatis. Molestias magni odio tempora maxime fugiat quas similique. Quis debitis similique dolores possimus nemo. Omnis labore omnis neque animi inventore dolores.'),(41,1,'Molestiae quae atque expedita aperiam. Eligendi dolores aspernatur nihil nisi quidem molestiae. Molestiae id sapiente aut delectus aut. Pariatur illo reprehenderit dolorum corporis.'),(42,2,'Reprehenderit velit magnam recusandae aut vitae est amet. Architecto magnam quis minima nisi voluptates et dicta. Deleniti omnis labore labore cum nisi nihil magnam.'),(43,3,'Rerum eos pariatur ab voluptates. Quae quaerat fugit omnis excepturi earum dolores. Dolorem aspernatur voluptas natus. Aut omnis qui eveniet facere.'),(44,4,'Et et consectetur quisquam consequatur facilis qui. Ut soluta consectetur odio exercitationem voluptatem sed. Reprehenderit reiciendis tempora nihil qui voluptas veniam est. Odit ea nemo dolorem beatae eaque voluptate dolores quia.'),(45,5,'Est est quibusdam recusandae dicta assumenda non et. Possimus quis minus quia. Ut cum aut iste non.'),(46,6,'Quaerat consequatur explicabo illo porro porro similique magni mollitia. Illo et cupiditate atque consequatur sed reprehenderit. Provident omnis esse libero corporis vero. Quo iste atque et enim ea.'),(47,7,'Tempora fugiat dolor sequi corrupti accusantium aut. Temporibus delectus maxime eos in quasi. Iure placeat illum dolore voluptas doloribus eum tempore maiores. Nemo dolorum cupiditate dolorem impedit. Numquam laborum quo labore et ut earum.'),(48,8,'Iusto tempore quo mollitia sapiente. Est officia facilis ipsa et nihil. Et explicabo sint cum consequatur. Ex est vel libero eos consequuntur.'),(49,9,'Error quibusdam autem vero sit molestias. Enim nesciunt est non quo dolorem aliquam. Sed cupiditate et praesentium voluptatem itaque inventore voluptatem. Est totam iusto non vel neque recusandae temporibus.'),(50,10,'Ut autem nihil ducimus vero error. Doloremque non id quia sed autem.'),(51,11,'Eligendi minus non qui odit. Distinctio perspiciatis pariatur modi laudantium ipsam provident iusto.'),(52,12,'Ullam iste aspernatur blanditiis. Autem quis adipisci totam ipsa. Aperiam et voluptate dolor cum fugiat quos ut. Dolores ex eius enim officiis est totam.'),(53,13,'Omnis voluptatem perspiciatis tempore assumenda id. Quo eum debitis itaque omnis nesciunt rerum labore. Necessitatibus ut ut et enim sed et nihil. Explicabo ducimus molestias vel quod. Optio iure cupiditate at.'),(54,14,'Sed quas laudantium qui rerum. Tenetur dolorem fugit nostrum. Atque expedita unde labore velit qui et aut aut.'),(55,15,'Et provident quia modi omnis accusantium vitae. Ab quod voluptas sed doloremque doloribus. Adipisci repellat fuga molestias voluptatum molestias.'),(56,16,'Ab laborum eveniet et repellat. Reprehenderit provident dolores aperiam soluta nihil et. Labore reiciendis dolor a voluptate sapiente. Eaque sapiente rerum maiores architecto.'),(57,17,'Consectetur voluptas et qui totam. Sint quia similique optio rerum. Sed laudantium fuga quos ut error.'),(58,18,'Et qui mollitia et qui placeat aut. Ea odio est sed velit. Exercitationem corrupti voluptatum qui iste veritatis. Perferendis reprehenderit repellat suscipit dolore.'),(59,19,'Numquam error officiis voluptatem voluptatem facere perferendis. Laudantium et sint dicta molestiae iure nam in ut. Rem numquam cupiditate molestias deserunt ex similique.'),(60,20,'Aut est ut nihil exercitationem est nostrum doloremque. Et temporibus et provident. Incidunt impedit rerum nesciunt iusto dolorem non minima.'),(61,1,'Omnis autem odio omnis aperiam ex illo sapiente. Quis totam odit cumque culpa. Qui ut optio repudiandae qui corrupti soluta minus.'),(62,2,'Enim explicabo reiciendis rerum aut maxime nostrum. Dolor optio accusantium qui assumenda omnis eligendi ipsum distinctio. Aut quae quas et nostrum reprehenderit quia maxime. Itaque fuga voluptates eos fugiat.'),(63,3,'Cupiditate aliquid incidunt excepturi. Omnis et aut qui qui qui odit. Culpa omnis a quam iste. Quibusdam culpa asperiores tenetur dolores sapiente ut at.'),(64,4,'At ipsam officiis amet placeat sint id quis. Amet doloremque expedita laborum eum et magni ut magnam. Sunt cum nisi omnis neque et qui nam et. Autem rerum omnis ratione dolore eius.'),(65,5,'Fugit neque iste esse repellat. Cum libero rerum voluptatem et dolor similique rerum. Quae fugit et autem est molestiae.'),(66,6,'Suscipit amet est ex odit architecto reprehenderit. Consequuntur sunt molestias quaerat recusandae omnis dolorum.'),(67,7,'Nam in quis sint provident sequi. Facere dolore pariatur vel dolorem possimus ut repudiandae placeat. Assumenda consequatur deleniti iure optio.'),(68,8,'Labore asperiores commodi cumque maxime magnam. Sunt quia quisquam sequi odit. Expedita quis ut sed error quas corporis.'),(69,9,'Dolorum error deleniti sed ab voluptatem. Minus voluptatum harum error quis quaerat excepturi provident. Recusandae tenetur reiciendis aut maxime sint. Alias repudiandae reiciendis autem libero odit libero. Omnis temporibus corporis quia ad modi.'),(70,10,'Ab iusto ut eveniet ipsum maxime quas. Sunt officia doloribus at ducimus nihil excepturi nesciunt. Nihil laudantium at autem ut et. Nulla facere qui nostrum vero nihil mollitia ab.'),(71,11,'Qui quam maiores dolor molestiae sint. Ut amet accusantium repudiandae molestiae est architecto mollitia. Adipisci aut non quam.'),(72,12,'Sequi architecto veritatis accusantium et eaque voluptatem perspiciatis. Non sed cum fugit mollitia suscipit excepturi. Dolores cumque tempora doloribus est sed sint. Asperiores autem placeat iusto ducimus voluptatem.'),(73,13,'Magni ratione adipisci dolorem beatae voluptatibus. Accusamus sapiente ex numquam autem. Aut est doloribus error.'),(74,14,'Nesciunt qui in et autem aliquam consequatur nobis amet. Magni ad impedit illum fugit quasi dolorem quia. Quia sunt eligendi incidunt molestias qui rerum praesentium.'),(75,15,'Qui voluptas maiores voluptatem non eos aspernatur. Est autem odio numquam. Suscipit quis quia consequuntur.'),(76,16,'Aut qui voluptates aperiam qui nemo dolor voluptates. Architecto dolorum distinctio dolores sunt culpa quod laborum. Eius ratione earum aut adipisci officiis ullam fugiat. Nisi molestias ea odio assumenda quia delectus.'),(77,17,'Voluptatem blanditiis distinctio nihil laudantium excepturi esse est dolores. Vel sequi laudantium officiis ut eos. Quibusdam est et minus at qui. Et quia sequi qui porro.'),(78,18,'Accusamus aut sunt voluptatem beatae. Recusandae sit aut quia atque iusto. Pariatur ut vel quibusdam dolore dolorem provident vel.'),(79,19,'Placeat quia earum maxime dignissimos et quibusdam. Impedit voluptatem est vitae dignissimos ut tempora eum. Aut non quos soluta alias. Dicta ea suscipit ut et placeat. Voluptatem nihil aspernatur totam dignissimos facilis suscipit quia sed.'),(80,20,'Necessitatibus et qui ipsa et. Eaque at ipsum sit et. Voluptas temporibus qui recusandae ipsum qui non et. Numquam eum non quia possimus.'),(81,1,'Eaque omnis dolorem deleniti autem sed ut. Ea laudantium et culpa ipsum eveniet doloribus enim.'),(82,2,'Repellendus dolor similique quo earum molestias omnis. Voluptatum laudantium voluptas itaque qui repellendus alias. Velit consequatur mollitia odit tenetur quo natus.'),(83,3,'Laudantium exercitationem dolorem deserunt aut. Rerum ut fugit sit voluptatum nihil rerum eius. Facilis eligendi eos id necessitatibus et porro.'),(84,4,'Sed aliquid dolores aut ad corporis autem. Accusantium laudantium id dolor voluptatem est.'),(85,5,'Dolores est possimus libero sit. Rerum sequi suscipit ut alias illo neque laudantium. Deleniti consequuntur rerum libero odit.'),(86,6,'Vel quasi debitis a veritatis sint accusamus quia. Et omnis hic ullam est et earum ab. Omnis dolores illum at distinctio molestiae sit. Quia et eos et molestiae.'),(87,7,'Blanditiis modi dolor enim mollitia iure et voluptatem occaecati. Libero dolor ullam veritatis. Molestias nihil delectus reiciendis nemo dolor veniam. Esse sapiente eum qui et sunt ab molestias assumenda.'),(88,8,'Neque asperiores maiores est et omnis distinctio. Ullam esse non excepturi ea labore magnam. Similique ratione quia porro repellat aliquid voluptatem quasi. Mollitia impedit voluptatem optio velit quae blanditiis quas. Eaque dolores in sunt in voluptates maxime.'),(89,9,'Assumenda rerum aut at sed quia rem asperiores. Debitis vel alias doloremque harum rerum soluta nihil omnis. Et maiores aut autem. Veniam sint qui dicta eum dolorem minima facilis voluptatem.'),(90,10,'Natus eos ut aut ducimus. Aliquam tempora omnis doloribus sed aperiam. Ducimus sapiente veritatis autem vero corrupti.'),(91,11,'Expedita qui maiores dicta sed enim reprehenderit error. In molestias voluptate ipsam quia dicta. Tempore et consequatur consequatur velit ex dignissimos necessitatibus.'),(92,12,'Quia quasi excepturi ipsam amet accusantium. Id repellendus dolor placeat rerum. Blanditiis ad voluptas rerum officia quaerat eos. Illum non et voluptas voluptas est modi itaque enim.'),(93,13,'Adipisci beatae placeat quia quasi dolores aut pariatur eos. Esse perspiciatis alias dolorem possimus. Rerum eius animi ut amet. Ipsum animi quia ipsum at cupiditate non illo.'),(94,14,'Fuga repudiandae maiores ut inventore voluptatem qui maiores. Dignissimos dolor necessitatibus et tempore voluptas et non. Veniam commodi impedit sapiente aliquid quam perferendis magnam. Et aut quibusdam qui nam aspernatur sed.'),(95,15,'Hic deleniti eum dolor ratione aut. Ut consequatur dolorum ipsum modi explicabo esse.'),(96,16,'Voluptatibus et ut neque aperiam ut ut quos. Eos similique laudantium natus labore perspiciatis possimus et ex. Praesentium perferendis rem ipsam vel facilis non. Maiores perferendis fugiat cupiditate.'),(97,17,'In qui odio mollitia velit dolorum. Molestiae laudantium alias praesentium inventore esse. Est sit eum quia inventore qui cum. Eveniet dolores aut nesciunt molestiae ratione corrupti in.'),(98,18,'Quaerat possimus neque est repudiandae. Deserunt atque eum non animi. Ex error molestiae doloribus suscipit aut. Eum et veniam quisquam ad consequatur omnis quia.'),(99,19,'Natus aperiam quis qui. Deserunt maiores quia rem aspernatur minima. Praesentium enim voluptatem provident.'),(100,20,'Aut voluptas consequatur aut debitis veritatis cum. Atque nostrum laboriosam iste eaque. Esse et blanditiis reprehenderit illo ut minima veniam. Neque saepe iste qui officia architecto labore.');
INSERT INTO `users_posts` VALUES (1,1),(2,2),(3,3),(4,4),(5,5),(6,6),(7,7),(8,8),(9,9),(10,10),(11,11),(12,12),(13,13),(14,14),(15,15),(16,16),(17,17),(18,18),(19,19),(20,20);
INSERT INTO `communities_posts` VALUES (1,1),(2,2),(3,3),(4,4),(5,5),(6,6),(7,7),(8,8),(9,9),(10,10),(11,11),(12,12),(13,13),(14,14),(15,15),(16,16),(17,17),(18,18),(19,19),(20,20);


