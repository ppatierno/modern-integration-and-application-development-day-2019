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

Deploy the initial Apache Kafka cluster by running:

```bash
oc apply -f 01-starting-cluster.yaml
```

It create a `Kafka` resource which the Cluster operator takes care for creating the Apache Kafka cluster.
The Cluster operator also starts the Topic and User operators for handling topics and users via `KafkaTopic` and `KafkaUser` resources.

# Updating Apache Kafka cluster configuration

In order to expose the Kafka cluster outside of the Kubernetes/OpenShift cluster, we have to update the deployed `Kafka` resource by running:

```bash
oc apply -f 01-update-cluster.yaml
```

# Creating topic, user and exporting certificates

The demo has an `iot-device-data` topic where the data are sent to.
The device, connecting from outside the cluster, is authenticated via TLS as `my-device` user and simple authentication is used for allowing it to write to the `iot-device-data` topic.
A Camel-Kafka-Influxdb application is running in the Kubernetes/OpenShift cluster for getting data from the `iot-device-data` and putting them to Influxdb. It uses a `camel-kafka-influxdb` user with SCRAM-SHA-512 authentication (username/password).

The topic and the users are created by running:

```bash
oc apply -f 03-topic-users.yaml
```

Export the certificates related to access via TLS and client authentication by running:

```bash
./get-device-keys.sh
```

It creates three files: `ca.crt`, `user.crt` and `user.key`.

# Deploy Influxdb, Grafana and Camel-Kafka-Influxdb application

The Influxdb can be deployed by running:

```bash
oc apply -f https://github.com/ppatierno/kafka-iot-influxdb/blob/master/deployment/influxdb.yaml
```

The Grafana interface by running:

```bash
oc apply -f https://raw.githubusercontent.com/strimzi/strimzi-kafka-operator/0.11.1/metrics/examples/grafana/grafana.yaml
oc expose service/grafana
```

And then setting Influxdb as datasource and importing the dashboard from:

```
https://raw.githubusercontent.com/ppatierno/kafka-iot-influxdb/master/dashboard/kafka-iot-dashboard.json
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
export USER_CRT=$(cat <path to user.key file>)
```

Export the `BOOTSTRAP_SERVERS` env var to the external listener route of the Kafka cluser.

```bash
export BOOTSTRAP_SERVERS=<external listener route>
```

Finally, start the `device-app` by running:

```bash
./scripts/run.sh ./target/device-app.jar
```