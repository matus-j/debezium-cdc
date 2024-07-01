CREATE DATABASE sampledb;
GO

USE sampledb;
GO

CREATE TABLE Users (
    ID INT PRIMARY KEY,
    Name NVARCHAR(50),
    Email NVARCHAR(50),
    Birthday DATE
);
GO

INSERT INTO Users (ID, Name, Email, Birthday) VALUES (1, 'Harry Potter', 'harry.potter@hogwarts.com', '1980-07-31');
INSERT INTO Users (ID, Name, Email, Birthday) VALUES (2, 'Hermione Granger', 'hermione.granger@hogwarts.com', '1979-09-19');
INSERT INTO Users (ID, Name, Email, Birthday) VALUES (3, 'Ron Weasley', 'ron.weasley@hogwarts.com', '1980-03-01');
INSERT INTO Users (ID, Name, Email, Birthday) VALUES (4, 'Luke Skywalker', 'luke.skywalker@rebellion.com', '1951-09-25');
INSERT INTO Users (ID, Name, Email, Birthday) VALUES (5, 'Darth Vader', 'darth.vader@empire.com', '2011-09-12');
INSERT INTO Users (ID, Name, Email, Birthday) VALUES (6, 'Frodo Baggins', 'frodo.baggins@shire.com', '1951-09-25');
INSERT INTO Users (ID, Name, Email, Birthday) VALUES (7, 'Gandalf the Grey', 'gandalf@wizard.com', '1951-09-25');
INSERT INTO Users (ID, Name, Email, Birthday) VALUES (8, 'Tony Stark', 'tony.stark@starkindustries.com', '1970-05-29');
INSERT INTO Users (ID, Name, Email, Birthday) VALUES (9, 'Bruce Wayne', 'bruce.wayne@wayneenterprises.com', '1972-02-19');
INSERT INTO Users (ID, Name, Email, Birthday) VALUES (10, 'Clark Kent', 'clark.kent@dailyplanet.com', '1979-06-18');
GO

CREATE TABLE Orders (
    ID INT PRIMARY KEY,
    UserID INT,
    OrderDate DATE,
    TotalAmount DECIMAL(10, 2),
    Product NVARCHAR(255),
    FOREIGN KEY (UserID) REFERENCES Users(ID)
);

INSERT INTO Orders (ID, UserID, OrderDate, TotalAmount, Product) VALUES (1, 8, '2024-06-30', 120.50, 'Beer');
INSERT INTO Orders (ID, UserID, OrderDate, TotalAmount, Product) VALUES (9, 1, '2024-07-01', 200.00, 'Batman-Costume');

EXEC sys.sp_cdc_enable_db;
GO

EXEC sys.sp_cdc_enable_table 
    @source_schema = 'dbo', 
    @source_name = 'Users', 
    @role_name = NULL;
GO

CREATE LOGIN cdc_user WITH PASSWORD = 'cdc_Password?&';
GO

USE sampledb;
GO
CREATE USER cdc_user FOR LOGIN cdc_user;
GO

EXEC sp_addrolemember N'db_owner', N'cdc_user';
EXEC sp_addrolemember N'db_datareader', N'cdc_user';
EXEC sp_addrolemember N'db_datawriter', N'cdc_user';
GO

GRANT EXECUTE ON sys.sp_cdc_enable_table TO cdc_user;
GRANT EXECUTE ON sys.sp_cdc_disable_table TO cdc_user;
GRANT EXECUTE ON sys.sp_cdc_change_job TO cdc_user;
GRANT EXECUTE ON sys.sp_cdc_add_job TO cdc_user;
GRANT EXECUTE ON sys.sp_cdc_drop_job TO cdc_user;
GRANT EXECUTE ON sys.sp_cdc_start_job TO cdc_user;
GRANT EXECUTE ON sys.sp_cdc_stop_job TO cdc_user;
GO

GRANT CONTROL ON SCHEMA::cdc TO cdc_user;
GO

GRANT SELECT ON ALL TABLES TO cdc_user;
GO

GRANT VIEW SERVER STATE TO cdc_user;
GO

GRANT VIEW SERVER PERFORMANCE STATE TO cdc_user;
GO