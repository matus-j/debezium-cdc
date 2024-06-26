CREATE DATABASE sampledb;
GO

-- Use database
USE sampledb;
GO

CREATE TABLE Users (
    ID INT PRIMARY KEY,
    Name NVARCHAR(50),
    Email NVARCHAR(50)
);
GO

-- Insert example data
INSERT INTO Users (ID, Name, Email) VALUES (1, 'Harry Potter', 'harry.potter@hogwarts.com');
INSERT INTO Users (ID, Name, Email) VALUES (2, 'Hermione Granger', 'hermione.granger@hogwarts.com');
INSERT INTO Users (ID, Name, Email) VALUES (3, 'Ron Weasley', 'ron.weasley@hogwarts.com');
INSERT INTO Users (ID, Name, Email) VALUES (4, 'Luke Skywalker', 'luke.skywalker@rebellion.com');
INSERT INTO Users (ID, Name, Email) VALUES (5, 'Darth Vader', 'darth.vader@empire.com');
INSERT INTO Users (ID, Name, Email) VALUES (6, 'Frodo Baggins', 'frodo.baggins@shire.com');
INSERT INTO Users (ID, Name, Email) VALUES (7, 'Gandalf the Grey', 'gandalf@wizard.com');
INSERT INTO Users (ID, Name, Email) VALUES (8, 'Tony Stark', 'tony.stark@starkindustries.com');
INSERT INTO Users (ID, Name, Email) VALUES (9, 'Bruce Wayne', 'bruce.wayne@wayneenterprises.com');
INSERT INTO Users (ID, Name, Email) VALUES (10, 'Clark Kent', 'clark.kent@dailyplanet.com');
GO

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

EXEC sp_addrolemember N'db_owner', N'cdc_user';  -- Assigning db_owner role
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