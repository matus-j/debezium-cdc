## Single DB Table Sync from MySQL to PostgreSQL (JSON)

### Setup:
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
- **Data Types Mapping**: Ensure accurate mapping of data types
- **Source Change**: Use SQL Server as a source instead of MySQL
- Use [Avro](https://debezium.io/documentation/reference/stable/configuration/avro.html) instead of JSON


## Database Management

##### phpMyAdmin
- **URL**: [phpMyAdmin](http://localhost:8081)
- **Host**: user
- **Root Password**: userpassword

##### pgAdmin
- **URL**: [pgAdmin](http://localhost:8082)
- **Email**: admin@admin.com
- **Password**: admin
- **Host**: postgres
- **Database Name**: sampledb
- **DB-Username**: user
- **DB-Password**: password




## Kafka Connect
Get all available Plugins
```
 curl localhost:8083/connector-plugins | json_pp
```
Register Connector
```
curl -X POST -H "Content-Type: application/json" --data @kafka-connect/mysql-connector.json http://localhost:8083/connectors
```
