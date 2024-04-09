#!/usr/bin/env bash
set -euxo pipefail

docker build -t testimage .
docker run -d -p 1521:1521 -e ORACLE_PASSWORD=password testimage
