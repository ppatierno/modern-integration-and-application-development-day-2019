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