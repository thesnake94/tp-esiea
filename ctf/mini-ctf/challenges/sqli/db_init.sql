DROP DATABASE IF EXISTS ctf;
CREATE DATABASE ctf;
USE ctf;

CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50),
  password VARCHAR(50)
);
INSERT INTO users (username,password) VALUES ('alice','alicepass'),('bob','bobpass');

CREATE TABLE flags (
  id INT AUTO_INCREMENT PRIMARY KEY,
  flag VARCHAR(255)
);
INSERT INTO flags (flag) VALUES ('FLAG{sql_injection_success}');
