# Statefulset

## Installation

In order to install mssql into kubernetes, the following files and structure is needed.

```console
└── mssql
    ├── base
    │   ├── configmap.yaml
    │   ├── kustomization.yaml
    │   ├── pvc.yaml
    │   ├── secret.yaml
    │   ├── service.yaml
    │   ├── serviceaccount.yaml
    │   └── statefulset.yaml
    └── overlay
        ├── global-labels.yaml
        ├── kustomization.yaml
        └── patch-statefulset.yaml
```

```bash
# Prompt to the child overlay
cd /mssql/overlay/
        
# Get the kustomize built manifest generated from patches applied from base
kubectl apply -k . --dry-run=client -o yaml> mssql-build.yaml
         
# Manually, to install mssql run following commands
kubectl create namespace database
kubectl apply -k . 
         
# Use following command to forward the mssql port to local
kubectl port-forward -n database svc/mssql 1433
```

Following limitations must be considered:

* Replication is not supported.
* Replica must be equal to 1
  * ERROR: /opt/mssql/bin/sqlservr: Another instance of the application is already running.
* Headless service is been used (clusterIP: None).

```yaml
apiVersion: v1
kind: Service
metadata:
    name: mssql
    labels:
    app.kubernetes.io/name: mssql
spec:
    clusterIP: None
    ports:
    - port: 1433
        targetPort: http
        protocol: TCP
    selector:
    app.kubernetes.io/name: mssql
```

```bash
# Run utils
kubectl run utils -n micro -it  --rm --image eddiehale/utils bash

# Get the ip using the pod name and Headless service (pod-name.headless-service.namespace)
nslookup mssql-0.mssql.database.svc.cluster.local
nslookup mssql-1.mssql.database.svc.cluster.local
```

## Test

### Dbeaver

```bash
# Use following command to forward the mssql port to local
kubectl port-forward -n database svc/mssql 1433
```

Create new Ms SQL Server connection and use following connection data. (`sa/Passw0rd`)

### JDBC

Add follownig dependency into pom.xml project file

```yaml
<!-- https://mvnrepository.com/artifact/com.microsoft.sqlserver/mssql-jdbc -->
<dependency>
    <groupId>com.microsoft.sqlserver</groupId>
    <artifactId>mssql-jdbc</artifactId>
    <!--version>10.2.0.jre11</version-->
</dependency>
```

Use following jdbc connection to connect from Pods and different namespaces

`jdbc:sqlserver://mssql-0.mssql.database.svc.cluster.local:1433;databaseName=tempdb;user=sa;password=Passw0rd";`

### Mssql-tools

```bash
# Create pod with mssql-tool (micro namespace)
kubectl run -it --rm mssql-tools -n micro --image=mcr.microsoft.com/mssql-tools sh ## try use -- sh

# Use folowing commands within thre Pod
cd /opt/mssql-tools/bin/
./sqlcmd -S mssql-0.mssql.database.svc.cluster.local -d tempdb -U sa -P Passw0rd 
```

```bash
# List all databases
1>select name from sys.databases;
2>go

# List All Tables
1> select * from tempdb.information_schema.tables;
2> go
```

### References

* https://hub.docker.com/_/microsoft-mssql-server 
* https://cloudblogs.microsoft.com/sqlserver/2018/12/10/availability-groups-on-kubernetes-in-sql-server-2019-preview/ 
* https://github.com/microsoft/mssql-docker/tree/master/linux/sample-helm-chart-statefulset-deployment 
