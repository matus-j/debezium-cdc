## Single DB Table Sync from SQLServer to PostgreSQL

### Setup
```bash
docker-compose up -d
```
Register (Source, Debezium JDBC Sink and Non Debezium JDBC Sink) connectors (located in ./kafka-connect):
```bash
./register-connectors.sh
```

### Keep in Mind:
- **Topic Name to DB-Name Issue**: Due to Debezium naming conventions, the topic name may lead to errors. Adjustments were required: [Doc](https://docs.confluent.io/kafka-connectors/jdbc/current/sink-connector/sink_config_options.html#data-mapping)
- **JSON Converter** used
- **Single DB Table**: Automatic mapping of data types is questionable (?)

### Connector Used:
[JDBC Sink Connector](https://docs.confluent.io/kafka-connectors/jdbc/current/sink-connector/overview.html#jdbc-sink-connector-for-cp)  
**Reason**: Debezium JDBC Connector does not work with the Confluent platform image (issue unresolved)  
Error after registering JDBC Sink Connector:
```bash
curl -X GET http://localhost:8083/connectors/debezium-sink-connector/status
```
Error:  
```plaintext
"Caused by: com.fasterxml.jackson.databind.JsonMappingException: Scala module 2.13.5 requires Jackson Databind version >= 2.13.0 and < 2.14.0 - Found jackson-databind version 2.14.2"
```

### TODO:
- **Database History/Snapshot**: Transfer history and handle large data volumes
- **Data Types Mapping**: Ensure accurate mapping of data types, (probably) resolved by:
- Use [Avro](https://debezium.io/documentation/reference/stable/configuration/avro.html) instead of JSON


## Database Management

##### [pgAdmin](http://localhost:8082)
- **Email**: admin@admin.com
- **Password**: admin
- **Host**: postgres
- **Database Name**: sampledb
- **DB-Username**: user
- **DB-Password**: password

## SQL Server Connection

```bash
docker exec -it sql-server "bash"
```

```bash
/opt/mssql-tools/bin/sqlcmd -S localhost -U cdc_user -P "cdc_Password?&"
```
*or*
```bash
/opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "iLoveBillGate$"
```
Check if sampledb is available:
```sql
SELECT Name from sys.databases;
GO
```

```sql
USE sampledb;
select * from users;
GO
```
```sql
INSERT INTO Users (ID, Name, Email) VALUES (42, 'Jake Peralta', 'mangycarl@nypd.com');
```
```sql
DELETE FROM Users WHERE ID = 4;
```
```sql
UPDATE Users SET Name = 'Harry Kane', Email = 'harry.kane@fc.bayern' WHERE ID = 1;
```
--> Changes are reflected in PostgreSQL

### SQL Server Agent Status
Check SQL Server Agent Status:
```sql
1> use sampledb;
2> GO
Changed database context to 'sampledb'.
1> select case when dss.[status] = 4 then 1 else 0 end as isRunning
2> from sys.dm_server_services dss
3> where dss.[servicename] like N'SQL Server Agent (%';
4> GO
isRunning  
-----------
          1

(1 rows affected)
```
SQL Server Agent has to be running for CDC to work!

## Kafka Connect
Get all available Plugins
```
 curl localhost:8083/connector-plugins | json_pp
```
Register Connector
```
curl -X POST -H "Content-Type: application/json" --data @kafka-connect/mysql-connector.json http://localhost:8083/connectors