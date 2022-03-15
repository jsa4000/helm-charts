# Demo

## Installation

> Kubernetes > v1.22.x is required in order to follow this demo. (`kubectl get nodes`)

Install all the components:

* ArgoCD
* Sealed Secrets
* Istio Operator
* Istio
  * Kiali
  * Prometheus
  * Grafana
  * Jaeger
* Observability
  * Prometheus
  * Grafana
  * Loki
* MongoDB
* Components
  * SPA
  * Miroservices
    * Booking
    * Car
    * Hotel
    * Flight

```bash
# Use following command to bootstrap the components
./init.sh
```

Check if all the components are running (ArgoCD)

```bash
# Get the ArgoCD password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

# Access ArgoCD as admin user
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Check if all the pods are running

```bash
# Get all the pods
kubectl get pod --all-namespaces
```

## Demo

Verify the microservices are running and working properly

```bash
# Get all bookings
curl "http://localhost/booking/bookings" | jq .

# Check vehicle, flight and hotels available in databbase 
curl "http://localhost/car/vehicles/99" | jq .
curl "http://localhost/flight/flights/14" | jq .
curl "http://localhost/hotel/hotels/34" | jq .
```

Create booking each 2 minutes to create some traffic

```bash
# Set json data to send into the request
export CREATE_ALL_BOOKING_DATA='{
  "active": false,
  "clientId": "8fb3c723-7851-486e-a369-ba0f9b908198",
  "createdAt": "2021-10-18T08:06:00.391Z",
  "vehicleId": "99",
  "flightId": "14",
  "hotelId": "34",
  "fromDate": "2021-10-18T08:06:00.391Z",
  "id": "b9460d0a-248e-11e9-ab14-d663bd873d93",
  "toDate": "2021-10-18T08:06:00.391Z"
}'

# Perform the Request each 2 seconds
while true; do
echo "\n"Sending Booking Request 
curl -X POST "http://localhost/booking/bookings" \
-H  "accept: application/json" \
-H  "Content-Type: application/json" \
-d $CREATE_ALL_BOOKING_DATA
sleep 2
done
```

In order to use istio tools, it is recommended to use `istioctl` command line.

> Open three different terminals to open istio tools.

```bash
# Kiali Dashboards from Istio
istioctl dashboard kiali

# Jaeger Dashboard from Istio
istioctl dashboard jaeger

## Grafana dashboard from Prometheus Stack (http://localhost:3000) (`admin/prom-operator`)
kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80
```

Monitoring the traffic using the observability implemented in the system (Service Mesh + Logging + Metrics + Tracing)

[Kiali](http://localhost:20001)

1. Open kiali
2. Select Graph on the left panel
3. Select `micro` namespace, `Trafic` and `Versioned app graph` options
4. Display `Traffic Rate`, `Traffic Animation` and `Security`
5. Select `Hide` option to `Unknown node` in order to filter unnecessary nodes and visualize the Topology from `ingress` perspective.
6. Visualize the Topology such as `ingress`, `services`, `workloads`, `mongodb`, `dependencies`, etc..
7. Get the Total `HTTP (requests per second)` and http code rate, success and error.
8. Force error request to inject errors to see 5xx code.
9. Select a particular node in the graph to see specific values from that node.

[Jaeger](http://localhost:16686)

Tracing

1. Open Jaeger
2. Select `istio-ingressgateway.istio-system` service, `all` operations, lookback to `Last Hour` and Limit Results to `20`
3. Click `Find Traces` Button
4. Visualize the Top `graph` with the requests performed over time and the duration. Check anomalies in points with highest durations.
5. Check traces with `errors` and `sucessful`. The traces show spans with `duration` for each and som other `information`.
6. `Succesfull` traces are shown with the spans over the different services in parallel (reactive application).
7. Traces with `Èrrors` are shown in the same way, however an icon with an error is shown.

> Since traces are sent by the `sidecar` not the application, the specific exception and stacktrace is not shown asa if you have the tracing integrated directly in the apllication. For this, it can be used tools and frameworks such as `Open Telemetry` or `Sleuth`.

[Grafana](http://localhost:3000)

Metrics

1. Open Grafana
2. Use the **loupe** button on the left to see all the different dashboards
3. Select the `Kubernetes / Compute Resources / Node (Pods)` dashboard
4. Select the proper `datasource`, `node` and `time` (1 hour)
5. Check the `CPU Usage` and `Memory Usage` grahs by Pod and compare with each other.
6. Check the table view with additional information, `Usage`, `Requests`, `Percentages` and `limits`.
7. Select the `Node Exporter / Nodes` to see `CPU Usage`, `Memory Usage`, `Disk Usage`, `Disk I/O`, `Network`, etc..
8. Select other dashboards such as `Kubernetes / Networking / Pod` , etc.. to see aditional metrics.

> There are [dashboards](https://grafana.com/grafana/dashboards/) available for `Istio`, `Mongodb`, `Spring Applications`, and other `providers`.

Logs

1. Open Grafana
2. Select `Explore` on the left and select `Loki` datasource
3. Click `Logs browser` and select namespace `micro` and container `booking` and click `Show Logs`.
4. The same query can be expressed using a query language (`LogQL`) `{container="booking",namespace="micro"}`
5. View the `indexed` data and all the fields parsed. Fields can be filtered.
6. Also it can used the [query language](https://grafana.com/docs/loki/latest/logql/log_queries/) to see specific words or logs.
7. Errors can be filtered using following expression `{container="booking",namespace="micro"} |= "ERROR"`

## Additional

Force to get some specific traces and errors

```bash
# Set json data to send into the request
export CREATE_ALL_BOOKING_DATA='{
  "active": false,
  "clientId": "8fb3c723-7851-486e-a369-ba0f9b908198",
  "createdAt": "2021-10-18T08:06:00.391Z",
  "vehicleId": "99",
  "flightId": "14",
  "hotelId": "34",
  "fromDate": "2021-10-18T08:06:00.391Z",
  "id": "b9460d0a-248e-11e9-ab14-d663bd873d93",
  "toDate": "2021-10-18T08:06:00.391Z"
}'

# Perform the Request
curl -X POST "http://localhost/booking/bookings" \
-H  "accept: application/json" \
-H  "Content-Type: application/json" \
-d $CREATE_ALL_BOOKING_DATA \
| jq .

# Set json data to send into the request
export CREATE_CAR_BOOKING_DATA='{
  "active": false,
  "clientId": "8fb3c723-7851-486e-a369-ba0f9b908198",
  "createdAt": "2021-10-18T08:06:00.391Z",
  "vehicleId": "13",
  "fromDate": "2021-10-18T08:06:00.391Z",
  "id": "b9460d0a-248e-11e9-ab14-d663bd873d93",
  "toDate": "2021-10-18T08:06:00.391Z"
}'

# Perform the Request
curl -X POST "http://localhost/booking/bookings" \
-H  "accept: application/json" \
-H  "Content-Type: application/json" \
-d $CREATE_CAR_BOOKING_DATA \
| jq .

# Set json data to send into the request
export CREATE_ERROR_BOOKING_DATA='{
  "active": false,
  "clientId": "8fb3c723-7851-486e-a369-ba0f9b908198",
  "createdAt": "2021-10-18T08:06:00.391Z",
  "vehicleId": "13",
  "flightId": "140",
  "hotelId": "34",
  "fromDate": "2021-10-18T08:06:00.391Z",
  "id": "b9460d0a-248e-11e9-ab14-d663bd873d93",
  "toDate": "2021-10-18T08:06:00.391Z"
}'

# Perform the Request
curl -X POST "http://localhost/booking/bookings" \
-H  "accept: application/json" \
-H  "Content-Type: application/json" \
-d $CREATE_ERROR_BOOKING_DATA \
| jq .
```
