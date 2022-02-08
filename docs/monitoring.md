# Monitoring

## Metrics

Serve prometheus and Grafana dashboards using port-forward

```bash
## Prometheus dashboard (http://localhost:9090)
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090

## Grafana dashboard (http://localhost:3000) (`admin/prom-operator`)
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

## Using Ingress 
http://localhost/grafana
```

Install following dashboards into Grafana.

> Select the same `Prometheus` source for all of them

- Node Exporter Full: 1860
- Traefik: 4475
- Spring Boot Statistics: 6756
- MongoDB Exporter: 2583

In order to use Spring Boot Statistics, use the following data to show app information:

- **Instance**. the `IP:Port` value from `targets` in Prometheus. i.e. `10.1.0.17:8080`
- **Application**. the name of the application (`spring.application.name`) or pod-name in most cases (without the hash). i.e. `car-microservice`.

Instance and Application can be gathered from the tags also:

```bash
com_example_booking_controller_seconds_max{application="booking-microservice", class="com.example.booking.controller.BookingController", container="booking", endpoint="http", exception="none", instance="10.1.0.17:8080", job="booking-microservice-srv", method="findAllBookings", namespace="micro", pod="booking-microservice-65bc7b4694-fdvhl", service="booking-microservice-srv"}
```

## Logging

Access Grafana loki Logs

> If **Grafana** is already installed use Grafana from the Prometheus Stack. Loki is **automatically** added into sources and `Explore`

```bash
## Get the User and Password
kubectl get secret -n logging loki-grafana -o=jsonpath='{.data.admin-user}' | base64 --decode; echo
kubectl get secret -n logging loki-grafana -o=jsonpath='{.data.admin-password}' | base64 --decode; echo

## Access to Grafana Loki (http://localhost:3000)
kubectl port-forward -n logging svc/loki-grafana 3000:80
```

Get Logs from microservices:

- Open Grafana-Loki at http://localhost:3000
- Select left Menu Item `Explore` -> `Loki` (ComboBox)
- Click into `Log browser` and select `namespace` -> `micro` -> `Show Logs` button, or using `{namespace="micro"}` directly in the search text.
- Select the time range to search for the logs on the top.
- Press `Run Query` to search all results
- Similar to Kibana with the results filters can be added using + or -, column to view (single), etc... i.e. `{app="hotel",namespace="micro"}`
