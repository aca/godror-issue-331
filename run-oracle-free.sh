#!/usr/bin/env bash
set -euxo pipefail

cd image
docker build -t testimage .
docker run -p 1521:1521 -e ORACLE_PASSWORD=password testimage
