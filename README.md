### Kafka Connect
Get all available Plugins
```
 curl localhost:8083/connector-plugins | json_pp
```
Register Connector
```
curl -X POST -H "Content-Type: application/json" --data @kafka-connect/mysql-connector.json http://localhost:8083/connectors
```

### Kafka
Consume topic from CLI
```
kafka-console-consumer.sh --topic <TOPIC_NAME> --bootstrap-server localhost:9092 --from-beginning
```
show topics
```
kafka-topics.sh --list --bootstrap-server localhost:9092
```

#### Fehler
"Caused by: com.fasterxml.jackson.databind.JsonMappingException: Scala module 2.13.5 requires Jackson Databind version >= 2.13.0 and < 2.14.0 - Found jackson-databind version 2.14.2" für JDBC Sink Connector Registrierung