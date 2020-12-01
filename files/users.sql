DROP TABLE IF EXISTS `users`;

create table users ( 
  id INT AUTO_INCREMENT PRIMARY KEY,
  firstname VARCHAR(150) NOT NULL,
  lastname VARCHAR(150) NOT NULL,
  age INT UNSIGNED NOT NULL);

insert into users(`firstname`,`lastname`,`age`) values 
  ('alice','smith','25'),
  ('bob','johnson','30');

