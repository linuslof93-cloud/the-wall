#!/bin/sh

podman run -d \
  --name database \
  --network wall-net \
  -e POSTGRES_DB=walldb \
  -e POSTGRES_USER=walluser \
  -e POSTGRES_PASSWORD=wallpass \
  quay.io/kurs/postgresql:2026-10-29
