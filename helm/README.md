# HELM Chart installation

## Add Helm Repository

```bash
## Install repository
helm3 repo add jsa4000 https://jsa4000.github.io/helm-charts

# List all chart and current version
helm3 search repo jsa4000
```

## Install Pre-requisites

```bash
## Install `traefik` Chart into `tools` namespace
helm3 install -n tools --create-namespace traefik traefik/traefik --version 10.3.2 -f manifests/traefik-values.yaml

## Install `kube-prometheus-stack` Chart into `monitoring` namespace
helm3 install -n monitoring --create-namespace prometheus prometheus-community/kube-prometheus-stack --version 18.0.6 \
--set 'prometheus-node-exporter.hostRootFsMount=false'

# Install MongoDB chart into datastore namespace
helm3 install mongo --namespace datastore --create-namespace bitnami/mongodb --version 10.19.0 -f manifests/mongodb-values.yaml
```

Uninstall

```bash
# Export manifest path
export MANIFEST_DIR=manifests

## Install `traefik` Chart into `tools` namespace
helm3 delete traefik -n tools

## Install `kube-prometheus-stack` Chart into `monitoring` namespace
helm3 delete -n monitoring prometheus

# Install MongoDB chart into datastore namespace
helm3 delete mongo -n datastore
```


## Install Charts

```bash
# Install car-microservice chart
helm3 install car -n micro --create-namespace --dependency-update car-microservice 

# Install flight-microservice chart
helm3 install flight -n micro --create-namespace --dependency-update flight-microservice 

# Install hotel-microservice chart
helm3 install hotel -n micro --create-namespace --dependency-update hotel-microservice 

# Install booking-microservice chart
helm3 install booking -n micro --create-namespace --dependency-update booking-microservice 
```

## Verify installation

Verify if microservices are currently running (status)

```bash
# Get all the common resources created from previous chart
kubectl get -n micro pods -w

# Get the logs from the pod u
kubectl logs -n micro car-microservice-8ff49d869-xptgp -f

# Test microservice by using Port-forward(http://localhost:8080/swagger-ui/)
kubectl port-forward --namespace micro svc/car-microservice-srv 8080:80
# Get all the vehicles
curl "http://localhost:8080/vehicles" | jq .

# Test microservice by using Traefik Controller / Ingress (http://localhost/car/swagger-ui/)
curl "http://localhost/car/vehicles" | jq .

```

## Examples

```bash
# Get all bookings
curl "http://localhost/booking/bookings" | jq .

# Create Booking.

# Check vehicle, flight and hotels available in databbase 
curl "http://localhost/car/vehicles/13" | jq .
curl "http://localhost/flight/flights/14" | jq .
curl "http://localhost/hotel/hotels/34" | jq .

# Set json data to send into the request
export CREATE_ALL_BOOKING_DATA='{
  "active": false,
  "clientId": "8fb3c723-7851-486e-a369-ba0f9b908198",
  "createdAt": "2021-10-18T08:06:00.391Z",
  "vehicleId": "13",
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
