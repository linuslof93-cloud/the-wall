#!/bin/sh

podman run -d \
  --name the-wall \
  --network wall-net \
  -p 8080:8080 \
  localhost/the-wall:v1
