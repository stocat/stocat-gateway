#!/bin/sh

# Wait for Consul to be ready
until curl -s http://consul:8500/v1/status/leader | grep -q "[0-9]"; do
  echo "Waiting for Consul..."
  sleep 1
done

echo "Consul is ready. Importing configuration..."

# Import routes
curl --request PUT --data-binary @/consul-config/routes.yaml \
  http://consul:8500/v1/kv/config/gateway/routes.yaml

# Import JWT secret
curl --request PUT --data-binary @/consul-config/jwt-secret.txt \
  http://consul:8500/v1/kv/config/common/secrets/jwt-secret

echo "Configuration imported."
