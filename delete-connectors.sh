#!/bin/bash

DEFAULT_CONNECTORS=("mysql-source-debezium" "mysql-postgres-sink-connector")

CONNECTORS=("$@")
if [ ${#CONNECTORS[@]} -eq 0 ]; then
  CONNECTORS=("${DEFAULT_CONNECTORS[@]}")
fi

for CONNECTOR in "${CONNECTORS[@]}"; do
echo "-----------------------------------------------------------------"
  echo "Deleting connector: $CONNECTOR"
  curl -X DELETE http://localhost:8083/connectors/$CONNECTOR
  echo -e "\n $CONNECTOR deleted."
done