#!/bin/bash
set -euxo pipefail

sqlplus SYSTEM/password@//localhost:1521/FREEPDB1 <<EOF
ALTER SESSION SET CONTAINER=FREEPDB1;
CREATE EDITIONABLE TYPE "QUEUE_MESSAGE_TYPE" as object (seqno number, data varchar2 (4000));
/
EOF
