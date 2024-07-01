## Simple Sync from SQLServer to PostgreSQL

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
- Automatic mapping of data types is questionable

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

## Database Management

### [pgAdmin](http://localhost:8082)
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
Change some Data:
```sql
INSERT INTO Users (ID, Name, Email) VALUES (42, 'Jake Peralta', 'mangycarl@nypd.com');
DELETE FROM Users WHERE ID = 4;
UPDATE Users SET Name = 'Harry Kane', Email = 'harry.kane@fc.bayern' WHERE ID = 1;
GO
```
--> Changes are reflected in PostgreSQL
```sql
SELECT * from "Users";
```

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
```

## Debezium Schema History and Schema Change Topic
_Source: [Doc SQL Server Connector](https://debezium.io/documentation/reference/stable/connectors/sqlserver.html#sqlserver-schema-history-topic)_

Topics: `schema-history.sqlserver-source` and `sqlserver-source-debezium`

> LSN = Log Sequence Number; LSNs are used to track the sequence of transactions and changes in the database  

==> Connector can thus link older changes with operations. This makes the schema traceable for a specific "area" of the changes up to a specific LSN:
```json
  "position": {
    "commit_lsn": "00000028:000004e8:0001",
    "snapshot": true,
    "snapshot_completed": false
  },
```
==> This is used for connectors after failures or restarts, to know the schema for the data were it continues reading and emitting events
> ⚠️ The database schema history topic is for internal connector use only.
> In Debezium, there is no built-in mechanism for sink connectors to automatically use schema change topics to adjust data types in the destination database. (afaik)

That's why `typeName` and `typeExpression` of the history topics are the types of the source database. (despite also containing the jdbc type refrence)

## ...

### Debezium
- **Schema and Constraints:** Debezium does not transfer constraints or schema definitions automatically. Manual schema creation and maintenance in PostgreSQL are probably and unsurprisingly required

- **Data Type Mapping:** Automatic mapping of data types between SQL Server and PostgreSQL can be inconsistent (e.g. `DATE` as `int32`)

    ```json
          {
            "type": "int32",
            "optional": true,
            "name": "io.debezium.time.Date",
            "version": 1,
            "field": "Birthday"
          }
    ```

- **Schema change topics** should only be used by source connectors

- **Entity Ordering** can be a problem with Debezium, especially if PostgreSQL database has foreign key constraints. Mentioned [here](https://stackoverflow.com/questions/63457232/debezium-initial-data-snapshot-and-related-entities-order). _Note:_ [Debezium Topic Routing](https://debezium.io/documentation/reference/transformations/topic-routing.html) is not yet part of a stable release.

### Kafka Connect
- Debezium JDBC Sink Connector may not be compatible with certain Kafka Connect images, requiring workarounds like the JDBC Sink connector
- JSON converter is used in this setup! Avro makes probably more sense as outlined [here](https://debezium.io/blog/2016/09/19/Serializing-Debezium-events-with-Avro/)
- **[Regex Router](https://docs.confluent.io/platform/current/connect/transforms/regexrouter.html)** is used for JDBC Sink connector table naming


#### Dump 🗑️
-  >"We need to look at only the initial database loading. In my case, the database was around 250Gb of size (...) In our case, running the load takes from 2 to 4 hours to get 100% online on sink databases, depending on the usage of the systems."
[Medium](https://william-prigol-lopes.medium.com/how-i-solved-real-time-sync-between-sql-server-and-postgresql-with-apache-kafka-3ce6b0b75c)