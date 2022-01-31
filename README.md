# Kubernetes Helm Charts

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

This functionality is in beta and is subject to change. The code is provided as-is with no warranties. Beta features are not subject to the support SLA of official GA features.

## Usage

[Helm](https://helm.sh) must be installed to use the charts.
Please refer to Helm's [documentation](https://helm.sh/docs/) to get started.

Once Helm is set up properly, add the repo as follows:

```console
helm repo add jsa4000 https://jsa4000.github.io/helm-charts
```

You can then run `helm search repo jsa4000` to see the charts.

## Build

```console
## Package current Helm Chart version
helm3 package charts/microservice-chart-java
helm3 package charts/microservice-library-chart-java

## Recreate the Helm repository Index
helm3 repo index
```

## License

<!-- Keep full URL links to repo files because this README syncs from main to gh-pages.  -->
[Apache 2.0 License](https://github.com/jsa4000/helm-charts/blob/main/LICENSE).