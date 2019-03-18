# Modern integration and application development day 2019

This repository contains the demos from my talk "Strimzi: how Apache Kafka has fallen in love with Kubernetes" at [Modern integration and application development day 2019](https://www.redhat.com/it/events/modern-integration-and-application-development-day-milano-2019)

# Requirements

Start a local OpenShift cluster using [minishift](https://docs.okd.io/latest/minishift/getting-started/installing.html).

```bash
minishift start
```

> It is also possible to start a local Kubernetes cluster using [minikube](https://kubernetes.io/docs/setup/minikube/) or connecting to an already running cluster somewhere.

# Install Strimzi: the Apache Kafka operator

The [Strimzi](https://strimzi.io/) project is part of the [OperatorHub.io](https://www.operatorhub.io).
It can be installed through the Operator Lifecycle Manager (OLM) component which helps to manage operators in the cluster.
The OLM can be installed by a user who has cluster admin rights.
You can login as `system:admin` and give to the `developer` user (or the user you want to use) the `cluster-admin` rights by running:

```bash
oc login -u system:admin
oc adm policy add-cluster-role-to-user cluster-admin developer
oc login -u developer -p developer
```

Then install the OLM by running:

```bash
oc create -f https://raw.githubusercontent.com/operator-framework/operator-lifecycle-manager/master/deploy/upstream/quickstart/olm.yaml
```

The above command installs the OLM in the `olm` namespace.
Finally, install the Strimzi operator by running the following command:

```bash
oc create -f https://www.operatorhub.io/install/strimzi-cluster-operator.v0.11.1.yaml
```

The Strimzi operator is installed in the `operators` namespace and is usable from all namespaces in the cluster.
The operator starts to watch for `Kafka`, `KafkaMirrorMaker` and `KafkaConnect` resources in any namespace.

# Install the initial Apache Kafka cluster

You can create a new namespace where deploying the Apache Kafka cluster or just continue to use the default `myproject`.
Deploy the initial Apache Kafka cluster by running:

```bash
oc apply -f 01-starting-cluster.yaml
```

It create a `Kafka` resource which the Cluster operator takes care for creating the Apache Kafka cluster.
The Cluster operator also starts the Topic and User operators for handling topics and users via `KafkaTopic` and `KafkaUser` resources.

# Updating Apache Kafka cluster configuration

In order to expose the Kafka cluster outside of the Kubernetes/OpenShift cluster, we have to update the deployed `Kafka` resource by running:

```bash
oc apply -f 02-update-cluster.yaml
```

The Cluster operator starts a rolling update for the Apache Kafka brokers, restarting them one by one for updating the configuration.

# Deploy the IoT demo application

The demo application is about IoT.
It's based on a simulated device running outside of the cluster sending data (temperature and humidity) to the Apache Kafka cluster.
An Apache Camel based application bridges data from Apache Kafka to Influxdb and a Grafana dashboard is used for showing the values in real time.
This demo is available in the [kafka-iot-influxdb](https://github.com/ppatierno/kafka-iot-influxdb) project.

## Creating topic, user and exporting certificates

The demo has an `iot-device-data` topic where the data are sent to.
The device, connecting from outside the cluster, is authenticated via TLS as `my-device` user and the "simple" authentication is used for allowing it to write to the `iot-device-data` topic.
A camel-kafka-influxdb application is running in the Kubernetes/OpenShift cluster for getting data from the `iot-device-data` and putting them to Influxdb. It uses a `camel-kafka-influxdb` user with SCRAM-SHA-512 authentication (username/password).

The topic and the users are created by running:

```bash
oc apply -f 03-topic-users.yaml
```

The Topic and User operators, deployed by the Cluster operator alongside the Apache Kafka cluster, take care about the resources in the above file.
The Topic operator creates the `iot-device-data` topic described by the related `KafkaTopic` resource.
The User operator creates `my-device` and `camel-kafka-influxdb` users described by the related `KafkaUser` resources.

Export the certificates related to the access via TLS and client authentication for the `my-device` user by running:

```bash
./04-get-device-keys.sh
```

It creates three files: `ca.crt`, `user.crt` and `user.key`.
The `ca.crt` is the cluster CA certificate, used for signing the Kafka and Zookeeper nodes certificates, and it's needed for TLS connection.
The `user.crt` and `user.key` are used by the device for TLS client authentication.

# Deploy InfluxDB and Grafana

The Influxdb can be deployed by running:

```bash
oc apply -f https://raw.githubusercontent.com/ppatierno/kafka-iot-influxdb/master/deployment/influxdb.yaml
oc expose service/influxdb
```

The Grafana interface by running:

```bash
oc apply -f https://raw.githubusercontent.com/strimzi/strimzi-kafka-operator/0.11.1/metrics/examples/grafana/grafana.yaml
oc expose service/grafana
```

An OpenShift route is used for exposing the Grafana web console outside of the cluster.

Finally, it is possible to create the needed InfluxDB database for storing data, creating a new InfluxDB datasource in Grafana and the Kafka IoT dashboard by running:

```bash
./05-grafana.sh
```

# Deploy the Apache Camel to InfluxDB application

For bridging the Kafka ingested data to InfluxDB, the related Camel application is deployed by running:

```bash
oc apply -f 06-camel-kafka-influxdb.yaml
```

# Starting the device

Clone the [kafka-iot-influxdb](https://github.com/ppatierno/kafka-iot-influxdb) project.
Build the `device-app` by running.

```bash
cd device-app
mvn clean package
```

Export `CA_CRT`, `USER_CRT` and `USER_KEY` env vars from the exported certificates.

```bash
export CA_CRT=$(cat <path to ca.crt file>)
export USER_CRT=$(cat <path to user.crt file>)
export USER_KEY=$(cat <path to user.key file>)
```

Export the `BOOTSTRAP_SERVERS` env var to the external listener route of the Kafka cluser.

```bash
export BOOTSTRAP_SERVERS=$(oc get routes my-cluster-kafka-bootstrap -o jsonpath='{.status.ingress[0].host}':443)
```

Finally, start the `device-app` by running:

```bash
./scripts/run.sh ./target/device-app.jar
```