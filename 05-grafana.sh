#!/bin/bash

INFLUXDB_HOST_ROUTE=$(oc get routes influxdb -o=jsonpath='{.status.ingress[0].host}{"\n"}')

# create the "sensor" database
curl -X POST http://${INFLUXDB_HOST_ROUTE}/query --data-urlencode 'q=CREATE DATABASE "sensor"'

GRAFANA_HOST_ROUTE=$(oc get routes grafana -o=jsonpath='{.status.ingress[0].host}{"\n"}')

# create the InfluxDB datasource for Grafana
curl -X POST http://admin:admin@${GRAFANA_HOST_ROUTE}/api/datasources -d @grafana/datasource.json --header "Content-Type: application/json"
# create the Kafka IoT dashboard in Grafana
curl -X POST http://admin:admin@${GRAFANA_HOST_ROUTE}/api/dashboards/db -d @grafana/dashboard.json --header "Content-Type: application/json"