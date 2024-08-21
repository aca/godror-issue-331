#!/bin/bash
set -euxo pipefail

sqlplus SYSTEM/password@//localhost:1521/FREEPDB1 <<EOF
ALTER SESSION SET CONTAINER=FREEPDB1;
BEGIN
DBMS_AQADM.CREATE_QUEUE_TABLE (
  Queue_table => 'QTBL_XXX_DATA',
  Queue_payload_type => 'QUEUE_MESSAGE_TYPE',
  Sort_list => 'ENQ_TIME,PRIORITY',
  comment => 'XXX_DATA'
);
DBMS_AQADM.CREATE_QUEUE (
  Queue_name => 'AQ_XXX_DATA',
  Queue_table => 'QTBL_XXX_DATA',
  Queue_type => 0,
  Max_retries => 999999999,
  Retry_delay => 0,
  dependency_tracking => FALSE,
  comment => 'XXX_DATA'
);
DBMS_AQADM.START_QUEUE(queue_name => 'AQ_XXX_DATA');
END;
/
EOF
