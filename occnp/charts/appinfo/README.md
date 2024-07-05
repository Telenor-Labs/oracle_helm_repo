# How get application information?

This project obtains application information of a specific namespace in kubenetes.
The application information includes:

* service list
* service status
* ports exposed by the service

## How to use it

The program `appinfo` is installed to Kubernetes using helm:

```bash
helm install --namespace=xxx --name=xxx helm-chart/appinfo
```

## Helm variables

To customize appinfo install using Helm, use the `--set <key>=<value>` option in
the Helm command to override one or more values. The set of supported keys is shown in the table below.

| Key                       | Default Value           | Description            |
|---------------------------|-------------------------|------------------------|
| image                     | app_info                | Docker image name      |
| imageTag                  | latest                  | Docker image tag       |
| replicas                  | 1                       | replica count          |
| debug                     | false                   | debug/info (true/false)|
| watchMySQL                | false                   | Watch MySQL database   |
| replicationStatusCheck    | false                   | Flag to enable replication status check   |
| scrapeInterval            | 5                       | Scrape interval        |
| infraServices             | [ occne-db-monitor-svc.occne-infra ] | Infra services |

If `watchMySQL` is set to `true`, then `dbStatusUri` and `realtimeDbStatusUri` are needed.
If `replicationStatusCheck` is set to `true`, then `replicationUri` is needed.

## API specification

### Get /status

Get the detailed status.

Example:

```txt
[appinfo@trent-pcf12-appinfo-674ff7b6b5-4bmpf app]$ curl localhost:8000/status
{
  "namespace": "trent-pcf12",
  "replication_status": "Fail",
  "service_categories": {
    "common": {
      "calculated_status": "Running",
      "critical_services": [],
      "depends_on": [],
      "details": {
        "trent-pcf12-occnp-audit": "Running",
        "trent-pcf12-occnp-binding": "Running",
        "trent-pcf12-occnp-config-mgmt": "Running",
        "trent-pcf12-occnp-config-server": "Running",
        "trent-pcf12-occnp-ldap-gateway": "Running",
        "trent-pcf12-occnp-perf-info": "Running",
        "trent-pcf12-occnp-policy-ds": "Running",
        "trent-pcf12-occnp-query": "Running"
      },
      "status": "Running"
    },
    "database": {
      "calculated_status": "Running",
      "critical_services": [],
      "depends_on": [],
      "details": {},
      "status": "Running"
    },
    "infra": {
      "calculated_status": "Running",
      "critical_services": [],
      "depends_on": [
        "database"
      ],
      "details": {},
      "status": "Running"
    },
    "pcf": {
      "calculated_status": "Running",
      "critical_services": [
        "trent-pcf12-occnp-pcf-sm",
        "trent-pcf12-occnp-pcf-ue",
        "trent-pcf12-occnp-pcf-am"
      ],
      "depends_on": [
        "infra",
        "common"
      ],
      "details": {
        "trent-pcf12-occnp-chf-connector": "Running",
        "trent-pcf12-occnp-pcf-am": "Running",
        "trent-pcf12-occnp-pcf-sm": "Running",
        "trent-pcf12-occnp-pcf-ue": "Running",
        "trent-pcf12-occnp-pre": "Running",
        "trent-pcf12-occnp-pre-test": "Running",
        "trent-pcf12-occnp-udr-connector": "Running"
      },
      "status": "Running"
    }
  },
  "service_details": {
    "mysql-connectivity-service": "Running",
    "ndbmgmdsvc": "Running",
    "ndbmtdsvc": "Running",
    "ndbmysqldsvc": "Running",
    "ndbmysqldsvc-0": "Running",
    "ndbmysqldsvc-1": "Running",
    "nf11stub": "Running",
    "nf12stub": "Running",
    "nf1stub": "Running",
    "nf21stub": "Running",
    "nf22stub": "Running",
    "nf2stub": "Running",
    "nf31stub": "Running",
    "nf32stub": "Running",
    "nf3stub": "Running",
    "ocamf2": "Running",
    "ocats-policy": "Running",
    "ocdns-stub": "Running",
    "trent-pcf12-altsvc-cache": "Running",
    "trent-pcf12-db-db-monitor-svc": "Running",
    "trent-pcf12-db-site1-site2-replication-svc": "Running",
    "trent-pcf12-egw-cache": "Running",
    "trent-pcf12-igw-cache": "Running",
    "trent-pcf12-occnp-alternate-route": "Running",
    "trent-pcf12-occnp-app-info": "Running",
    "trent-pcf12-occnp-audit": "Running",
    "trent-pcf12-occnp-binding": "Running",
    "trent-pcf12-occnp-chf-connector": "Running",
    "trent-pcf12-occnp-config-mgmt": "Running",
    "trent-pcf12-occnp-config-server": "Running",
    "trent-pcf12-occnp-egress-gateway": "Running",
    "trent-pcf12-occnp-ingress-gateway": "Running",
    "trent-pcf12-occnp-ldap-gateway": "Running",
    "trent-pcf12-occnp-nrf-client-cache": "Running",
    "trent-pcf12-occnp-nrf-client-nfdiscovery": "Running",
    "trent-pcf12-occnp-nrf-client-nfmanagement": "Running",
    "trent-pcf12-occnp-oc-diam-connector": "Running",
    "trent-pcf12-occnp-oc-diam-gateway": "Running",
    "trent-pcf12-occnp-oc-diam-gateway-headless": "Running",
    "trent-pcf12-occnp-pcf-am": "Running",
    "trent-pcf12-occnp-pcf-sm": "Running",
    "trent-pcf12-occnp-pcf-ue": "Running",
    "trent-pcf12-occnp-pcrf-core": "Running",
    "trent-pcf12-occnp-pcrf-core-headless": "Running",
    "trent-pcf12-occnp-perf-info": "Running",
    "trent-pcf12-occnp-policy-ds": "Running",
    "trent-pcf12-occnp-pre": "Running",
    "trent-pcf12-occnp-pre-test": "Running",
    "trent-pcf12-occnp-query": "Running",
    "trent-pcf12-occnp-udr-connector": "Running"
  }
}
```

### Get /serviceinfo/servicename/{name}

Get the external status of the service with a specific name.

Example:

```txt
[cloud-user@trent-east-bastion-1 ~]$ curl http://localhost:8000/serviceinfo/servicename/trent-app-pcf-ingress-gateway |python -m json.tool
{
    "trent-app-pcf-ingress-gateway": {
        "ipEndPoints": [
            {
                "ipv4Address": "10.113.2.172",
                "port": 5801,
                "transport": "TCP"
            },
            {
                "ipv4Address": "10.113.2.172",
                "port": 5701,
                "transport": "TCP"
            }
        ],
        "nfServiceStatus": "Running"
    }
}

```

### GET /serviceinfo/namespace/{namespace}/servicename/{name}

Get the external status of the service with a specific name in a namespace.

Example:

```txt
[cloud-user@trent-east-bastion-1 ~]$ curl http://localhost:8000/serviceinfo/namespace/trent/servicename/trent-app-pcf-ingress-gateway |python -m json.tool
{
    "trent-app-pcf-ingress-gateway": {
        "ipEndPoints": [
            {
                "ipv4Address": "10.113.2.172",
                "port": 5801,
                "transport": "TCP"
            },
            {
                "ipv4Address": "10.113.2.172",
                "port": 5701,
                "transport": "TCP"
            }
        ],
        "nfServiceStatus": "Running"
    }
}

```

### GET /status/category/{category}

Get the overall status of a category.

Example:

```txt
curl http://localhost:8000/status/category/pcf
Running
```

### GET /status/namespace/{namespace}/category/{category}

Get the overall status of a category in a namespace

Example:

```txt
[cloud-user@trent-east-bastion-1 ~]$ curl http://localhost:8000/status/namespace/trent/category/pcf
Running
```

### GET /serviceinfo/servicenamelist/{namelist}

Get the overall status of services in a namelist.

Example:

```txt
[cloud-user@trent-east-bastion-1 ~]$ curl http://localhost:8000/serviceinfo/servicenamelist/trent-app-pcf-amservice,trent-app-pcf-smservice
"Running"
```

### GET /replicationstatus

Get the replication status of the db tier service

Example:

```txt
curl http://localhost:8000/replicationstatus
Success
```
