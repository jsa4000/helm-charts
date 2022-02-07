# Helm Chart for SPA (Single Page Application)

## Manual Deployment

- Copy the following content from spa-chart into a folder

```txt
├── Chart.yaml
├── README.md
├── config
│   └── ..
├── secrets
│   └── ..
├── templates
│   ├── NOTES.txt
│   ├── _helpers.tpl
│   ├── configmap.yaml
│   ├── deployment.yaml
│   ├── destination-rule-orig-tls.yaml
│   ├── ingress.yaml
│   ├── secrets.yaml
│   ├── service-entry.yaml
│   └── service.yaml
└── values.yaml
```

- Copy the specific configuration for this spa/environment.

```txt
├── config
│   └── nginx.conf
├── secrets
│   ├── ..
└── values.yaml
```

- Create namespace

```
kubectl create namespace spa
```

- Switch to namespace

```
kubectl config set-context --current --namespace=spa
```

- Install the Chart

```bash
helm3 install spa -f values.yaml .

# Or into specific namespace already created
helm3 install spa -f values.yaml --namespace spa .
```

- List installed charts into current namespace

```bash
helm3 list
```

- Upgrade the chart

```bash
helm3 upgrade spa -f values.yaml .
```

- Delete the chart

```bash
helm3 delete spa
```