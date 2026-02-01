#!/bin/bash
export PATH=/usr/local/go/bin:$PATH
cd /root/projects/timingle2/backend

# Load environment variables from .env file
if [ -f .env ]; then
    set -a
    source .env
    set +a
    echo "Loaded environment from .env"
else
    echo "Warning: .env file not found, using defaults"
    # Fallback defaults
    export POSTGRES_HOST=localhost
    export POSTGRES_PORT=5432
    export POSTGRES_USER=timingle
    export POSTGRES_PASSWORD=timingle_dev_password
    export POSTGRES_DB=timingle
    export REDIS_HOST=localhost
    export REDIS_PORT=6379
    export NATS_URL=nats://localhost:4222
    export SCYLLA_HOST=localhost
    export SCYLLA_KEYSPACE=timingle
    export JWT_SECRET=dev-secret-key-change-in-production
    export PORT=8080
fi

./bin/api
