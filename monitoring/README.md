# Monitoring Stack

This directory contains a basic monitoring setup using the kube-prometheus-stack Helm chart.

## Components
- Prometheus (metric collection and storage)
- Alertmanager (alert handling)
- Grafana (visualization)
- kube-state-metrics (Kubernetes object metrics)
- node-exporter (node-level metrics)

## Usage

To deploy the monitoring stack:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace
```

## Integration with Existing Applications

The demo application in this repository is already configured to work with this monitoring stack:
- Service annotations for Prometheus scraping
- Metrics endpoint exposed on port 8000
- ServiceMonitor configuration would be added in a production setup

## Customization

For production use, consider:
- Setting up persistent storage for Prometheus
- Configuring alert receivers (Slack, email, etc.)
- Adding service-specific ServiceMonitor resources
- Implementing log aggregation (ELK/EFK stack)
- Adding distributed tracing (Jaeger/Tempo)