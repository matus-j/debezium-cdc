# Simple Sync from SQLServer to PostgreSQL
This project sets up Change Data Capture (CDC) from SQL Server to PostgreSQL using Debezium and Kafka using Docker.
## Setup
```bash
docker-compose up -d
```
Register (Source, Debezium JDBC Sink and Non Debezium JDBC Sink) connectors (located in ./kafka-connect):
```bash
./register-connectors.sh
```

#### Keep in Mind 🧠
- **Topic Name to DB-Name Issue**: Due to Debezium naming conventions, the topic name may lead to errors on the JDBC Sink Connector side. Adjustments were required: [Doc](https://docs.confluent.io/kafka-connectors/jdbc/current/sink-connector/sink_config_options.html#data-mapping)
- **JSON Converter** used

#### Connector Used:
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

### PostgreSQL: [pgAdmin](http://localhost:8082)
- **Email**: admin@admin.com
- **Password**: admin
- **Host**: postgres
- **Database Name**: sampledb
- **DB-Username**: user
- **DB-Password**: password

### SQL Server

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

## Troubleshooting
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

### Kafka Connect
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
> In Debezium, there is no built-in mechanism for sink connectors to automatically use schema change topics to adjust data types in the destination database.

That's why `typeName` and `typeExpression` of the history topics are the types of the source database. (despite also containing the jdbc type refrence)


### Create Schema before Registering Connectors
This section outlines the attempt to manually enforce constraints by creating the schema in PostgreSQL.
>💡 Note: Using INTEGER instead of DATE to avoid transfer errors, since source connector captures DATE as int32.

Idea: Manually create the PostgreSQL schema to ensure a robust schema with foreign key constraints.   
**SQL for the simple schema:**
```sql
CREATE TABLE "Users" (
    "ID" SERIAL PRIMARY KEY,
    "Name" VARCHAR(50),
    "Email" VARCHAR(50),
    "Birthday" INTEGER
);

CREATE TABLE "Orders" (
    "ID" SERIAL PRIMARY KEY,
    "UserID" INT,
    "OrderDate" INTEGER,
    "TotalAmount" DECIMAL(10, 2),
    "Product" VARCHAR(255),
    FOREIGN KEY ("UserID") REFERENCES "Users"("ID")
);
```
**Logged Error:**
```bash
2024-07-02 09:39:09 java.sql.SQLException: Exception chain:
2024-07-02 09:39:09 java.sql.BatchUpdateException: Batch entry 0 INSERT INTO "Orders" ("ID","UserID","OrderDate","TotalAmount","Product") VALUES (('9'::int4),('1'::int4),('19905'::int4),('200.00'::numeric),('Batman-Costume')) ON CONFLICT ("ID") DO UPDATE SET "UserID"=EXCLUDED."UserID","OrderDate"=EXCLUDED."OrderDate","TotalAmount"=EXCLUDED."TotalAmount","Product"=EXCLUDED."Product" was aborted: ERROR: insert or update on table "Orders" violates foreign key constraint "Orders_UserID_fkey"
2024-07-02 09:39:09   Detail: Key (UserID)=(1) is not present in table "Users".  Call getNextException to see other errors in the batch.
```
(Manually inserting data after ensuring the corresponding entries in "Users" are present works with the JDBC Sink Connector)

If the schema on the PostgreSQL side is "dumb" and doesn't enforce constraints, it works. However, this can lead to inconsistencies because constraints enforced only on the SQL Server side might not be mirrored in PostgreSQL.

#### Conclusion
Creating a robust schema in PostgreSQL before registering connectors helps maintain data integrity by enforcing constraints. However, this approach introduces potential complexities and issues:
1. Data Integrity
2. Transfer Errors
3. Consistency Issues

📝 **Note:** [Debezium Topic Routing](https://debezium.io/documentation/reference/stable/transformations/topic-routing.html) could help here, since the connector sorts changes based on their commit LSN and change LSN. This sorting ensures that changes are replayed in the same order they occurred in the database. However, this would make consuming the events more complex, since data for multiple tables would be mixed in one topic.



## Problems
### Schema Changes Not reflected
Add  column:
```sql
ALTER TABLE Users
ADD new_column INT;
UPDATE Users
SET new_column =  8
WHERE ID = 1;
GO
```
The new column and its data are not included in the events.

This issue is likely due to the source connector's include.schema.changes setting. By default, it should be set to true, but it appears that schema changes are not being propagated in this setup. This means that any alterations to the schema on the source database are not automatically reflected in the destination database, leading to inconsistencies and missing data fields.

Solution: WIP 


## General Conclusion

### Debezium
- **Schema and Constraints:** Debezium does not transfer constraints automatically. Manual schema creation and maintenance in PostgreSQL are probably required

- **Data Type Mapping:** Automatic mapping of data types between SQL Server and PostgreSQL can be inconsistent (e.g. `DATE` as `int32`)

- **Schema change topics** should only be used by source connectors

- **Entity Ordering** can be a problem with Debezium, especially if PostgreSQL database has foreign key constraints. Also mentioned [here](https://stackoverflow.com/questions/63457232/debezium-initial-data-snapshot-and-related-entities-order)  


### Kafka Connect
- Debezium JDBC Sink Connector may not be compatible with certain Kafka Connect images, requiring workarounds like the JDBC Sink connector

- JSON converter is used in this setup. Avro probably makes more sense as outlined [here](https://debezium.io/blog/2016/09/19/Serializing-Debezium-events-with-Avro/)

- **[Regex Router](https://docs.confluent.io/platform/current/connect/transforms/regexrouter.html)** is used for JDBC Sink connector table naming in this example