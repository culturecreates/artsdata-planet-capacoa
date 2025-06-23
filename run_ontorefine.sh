#!/bin/bash


# Start the services in the background
sudo docker compose up -d

# Wait for the server to start
echo "Waiting for server to start..."
while ! curl --output /dev/null --silent --head --fail http://localhost:7333; do
  sleep 5
done
echo "Server started!"

# Send a command to the running container
echo "Running OntoRefine CLI using config.json..."
sudo docker exec onto_refine /opt/ontorefine/dist/bin/ontorefine-cli transform ../data/members.json \
  -u http://localhost:7333  \
  --no-clean \
  --configurations ../data/ontorefine/ontorefine-config.json  \
  -f json >> ontorefine-output.ttl

# Open the default browser
open http://localhost:7333

echo "Open Project to edit the RDF Mapping."
