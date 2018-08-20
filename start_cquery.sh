#!/usr/bin/env sh
cquery --log-file /tmp/cquery_log.txt --init='{
  "cacheDirectory": "/tmp/cquery",
  "progressReportFrequencyMs": -1
}'
