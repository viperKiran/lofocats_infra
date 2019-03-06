# LofoCats Infrastructure

Simple example of creating an infrastructure for a customer app with Terraform and Kubernetes.

## Problematic

A customer needs an infrastructure to run their new Web application composed of 4 components packaged in Docker images:

* `ui`: [iridakos/lofocats_api](https://github.com/iridakos/lofocats_api)
* `api`: [iridakos/lofocats_api](https://github.com/iridakos/lofocats_api)
* `db`: [PostgreSQL](https://www.postgresql.org)
* `metrics`: [Prometheus](https://prometheus.io)

## Design proposal

### Technologies

* [Terraform](http://terraform.io) will be used to maintain the infrastructure as code
* The containers will be orchestrated by [Kubernetes](https://kubernetes.io) aka K8s
* A relational database service will be used for PostgreSQL to avoid dealing the hassles of managing it ourselves (e.g. K8s and stateful apps, upgrades, backups, high availability...).
* A managed Kubernetes service to avoid dealing with bootstrapping a cluster and maintaining it ourselves.
* [Google Cloud Platform](https://cloud.google.com/) aka GCP will be used as Cloud provider because they offer:
  * a RDS for PostgreSQL: [Cloud SQL](https://cloud.google.com/sql/)
  * a managed Kubernetes service: [Kubernetes Engine](https://cloud.google.com/kubernetes-engine) aka GKE
  * Google being the creator of Kubernetes just seems like a natural choice and it is well integrated with GCP.
    I didn't do any researches advanced concerning the features of each Cloud provider and their costs, but [AWS](https://aws.amazon.com/) and [Azure](https://azure.microsoft.com) could both be good candidates:
    * AWS has [RDS for PostgreSQL](https://aws.amazon.com/rds/postgresql/) and [Elastic Kubernetes Service](https://aws.amazon.com/eks/)
    * Azure has [Database for PostgreSQL](https://azure.microsoft.com/en-ca/services/postgresql/) and [Kubernetes Service](https://azure.microsoft.com/en-us/services/kubernetes-service/)

### Design

* The UI and API will configure via [Kubernetes Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) objects which will provide:
  * the necessary environment variables
  * [rolling updates](https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/)
  * scale and maintain the expected number of running replicas (via a [ReplicaSet](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/) objects)
* The UI and API will be accessible externally via HTTPS (with HTTP redirect), free TLS/SSL certificates will be provided by [Let's Encrypt](https://letsencrypt.org/) and managed automatically inside the K8s cluster by [cert-manager](https://github.com/jetstack/cert-manager)
* The Kubernetes nodes and CloudSQL database will be created inside a [VPC](https://cloud.google.com/vpc/) and only have private IPs
* The UI and API services will be exposed to the Internet via the GCE ingress controller since it is built-in and simple to use.
* The CloudSQL instance will be configured for high availability, scheduled backups
* In case of emergency, resources can be recreated with Terraform or from their Kubernetes manifest. The PostgreSQL instance can be also be [restored from a backup](https://cloud.google.com/sql/docs/postgres/backup-recovery/restoring).
* Terraform will automatically create a DNS record for the app public endpoint
* The `metrics` service (Prometheus) will be deployed in a similar fashion and its data will be stored in its own PostgreSQL instance using [timescale/prometheus-postgresql-adapter](https://github.com/timescale/prometheus-postgresql-adapter). The main difference will be that it won't be accessible publicly.
* Example of collected metrics:
  * The duration and number of requests
  * Exception and error number
  * Load average, memory and CPU usage
  * From aggregation and calculation:
    * Latency
    * Number of replicas for each service
    * Availability

### Possible future improvements

* If necessary, set up autoscaling for K8s nodes and application deployments
* Move away from Cloud provider specific services to make multi-cloud possible and simpler
  * Change [ingress-gce](https://github.com/kubernetes/ingress-gce) for a more flexible ingress controller (e.g. [ingress-nginx](https://github.com/kubernetes/ingress-nginx), [contour](https://github.com/heptio/contour), [istio](https://github.com/istio/istio)...)
  * Move PostgreSQL cluster inside the K8s cluster, possibly using an operator (e.g. [CrunchyData/postgres-operator](https://github.com/CrunchyData/postgres-operator), [zalando-incubator/postgres-operator](https://github.com/zalando-incubator/postgres-operator)...)
* Create a scheduled export of PostgreSQL data (possibly outside of GCP) to be able to restore outside of the project in case of emergency
* If its not already the case, I would recommend to development team to:
  * have a lightweight `/health` endpoint for liveness and readiness probes
  * have `/metrics` endpoint:
    * it would be scraped by Prometheus directly ([Pulling metrics is the recommended method](https://prometheus.io/docs/practices/pushing/))
    * If necessary, an exporter process running in a sidecar container can be implemented to format metrics into Prometheus format and would be a reusable component across your fleet of applications.
* Run Terraform and `kubectl apply` from a CI/CD pipeline, this would allow peer-review (code, plan, dry-run) and, for example, the master branch could be deployed to a staging environment and tag releases to the production environment. Optionally, temporary environments could be built for feature branches. The Kubernetes manifests could also be moved to the application repository to enable CI/CD directly from there.
* For a proprietary/private app, use a private registry for Docker images like [gcr.io](https://gcr.io) or self-hosted in the K8s cluster.
* Centralized logs for ease of analysis with an [ELK stack](https://www.elastic.co/elk-stack) (or EFK with [Fluentd](https://www.fluentd.org/)).
* Restrict access to management endpoints such as the Kubernetes master API to a company VPN.
* Metrics is something really important that would be necessary for all your applications. A common, more advanced and highly available infrastructure could be set up with [Thanos](https://github.com/improbable-eng/thanos).
* Docker images could be scanned for vulnerabilities using a tool like [Clair](https://github.com/coreos/clair)
* Rotate PostgreSQL credentials [with HashiCorp Vault](https://www.vaultproject.io/docs/secrets/databases/postgresql.html) or any other secrets


## Demo

Note: the demo is only a partial implementation of the design.

### Prerequisites

* This demo uses billable resources, you can choose your billing account by exporting its ID in `GOOGLE_BILLING_ACCOUNT` else the first found will be used (you can use `gcloud beta billing accounts list` to list them)
* Ensure you have the `gcloud` command-line tool installed and configured:
  https://cloud.google.com/sdk
* Ensure you have the `kubectl` command-line tool installed and configured:
  https://kubernetes.io/docs/tasks/tools/install-kubectl/
* You can choose your region by exporting `GOOGLE_REGION` (default: `us-central1`)

### Usage

* Run `./scripts/demo.sh`, this will:
  * Initialize the Google project
  * Create the storage for Terraform remote state
  * Build the infrastructure with Terraform
  * Deploy the Kubernetes manifest files to configure the app
  * Load the demo data
  * **Note**: the script is interactive for the safety of your GCP account, but after review, you should be able to type "yes" or "Y" for everything
* Then you can use the endpoint provided by `terraform output endpoint` to access the app over HTTP
  * The UI is served on `/`, see https://github.com/iridakos/lofocats_ui for details
  * The API is served on `/api/`, see https://github.com/iridakos/lofocats_api for details

### Clean up

* Delete the Google project:

```shell
gcloud projects delete "${GOOGLE_PROJECT}"
```

### ToDo

- [ ] Implement minimal [Prometheus](https://prometheus.io) monitoring
- [ ] Restrict access to metrics and health endpoints to the internal network
- [ ] Do not use a superuser to connect to the database
