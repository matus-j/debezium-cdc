CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL
);

# Debezium User Setup
CREATE USER 'hi-mom'@'%' IDENTIFIED BY '42';
GRANT SELECT, RELOAD, SHOW DATABASES, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'hi-mom'@'%';
FLUSH PRIVILEGES;

INSERT INTO users (name, email) VALUES
('Harry Potter', 'harry.potter@hogwarts.com'),
('Hermione Granger', 'hermione.granger@hogwarts.com'),
('Ron Weasley', 'ron.weasley@hogwarts.com'),
('Frodo Baggins', 'frodo.baggins@shire.com'),
('Samwise Gamgee', 'samwise.gamgee@shire.com'),
('Tony Stark', 'tony.stark@starkindustries.com'),
('Bruce Wayne', 'bruce.wayne@wayneenterprises.com'),
('Clark Kent', 'clark.kent@dailyplanet.com'),
('Diana Prince', 'diana.prince@themyscira.com'),
('Peter Parker', 'peter.parker@dailybugle.com');