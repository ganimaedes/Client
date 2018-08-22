#!/usr/bin/env sh
cquery_folder=`find "/home/$(id -u -n)" -type d -wholename "*cquery/build" 2>/dev/null`
"$cquery_folder"/cquery --log-file /tmp/cquery_log.txt --init='{
  "cacheDirectory": "/tmp/cquery",
  "progressReportFrequencyMs": -1
}'
