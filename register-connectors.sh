#!/bin/bash
echo "JSON Dateien der Registrierungen müssen im kafka-connect Ordner liegen!"

DEFAULT_CONNECTORS=("sqlserver-debezium.json" "debezium-sink-connector.json" "confluent-jdbc-sink-connector.json")

CONNECTOR_FILES=("${@:-${DEFAULT_CONNECTORS[@]}}")
STATUS_CONNECTOR=${3:-$DEFAULT_STATUS_CONNECTOR}

register_connector() {
  local file=$1
  local connector_name=$(basename "$file" .json)
  
  echo "Registrieren des Connectors $connector_name über die Connect API..."
  curl -X POST -H "Content-Type: application/json" --data @"kafka-connect/$file" http://localhost:8083/connectors
  echo -e "\nAPI Aufruf für $connector_name Registrierung durchgeführt."
  echo "---------------------------------------------------------------------------------"
}

for CONNECTOR_FILE in "${CONNECTOR_FILES[@]}"; do
  register_connector "$CONNECTOR_FILE"
done
