#!/bin/bash
NEG=/tmp/m9_negative
LOCAL=~/datalake_local/DataCoOrders_cleaned.csv
hdfs dfs -rm -r -f $NEG >/dev/null 2>&1
hdfs dfs -mkdir -p $NEG/missing_row $NEG/changed_value $NEG/mr_late_bad

echo "== N1: copy of the orders file with ONE row deleted"
sed '100d' $LOCAL | hdfs dfs -put -f - $NEG/missing_row/orders.csv
echo "   local lines: $(wc -l < $LOCAL)   damaged copy in HDFS: $(hdfs dfs -cat $NEG/missing_row/orders.csv | wc -l)"
[ "$(md5sum < $LOCAL | cut -d' ' -f1)" == "$(hdfs dfs -cat $NEG/missing_row/orders.csv | md5sum | cut -d' ' -f1)" ] \
  && echo "   MD5 check:  PASS   <- test did NOT catch the error" || echo "   MD5 check:  FAIL   <- error detected (expected)"

echo "== N2: copy of the orders file with ONE character changed (shipping days 3 -> 9 in one row)"
awk -F, -v OFS=, 'NR==2{$7=9} {print}' $LOCAL | hdfs dfs -put -f - $NEG/changed_value/orders.csv
echo "   lines are equal: $(wc -l < $LOCAL) vs $(hdfs dfs -cat $NEG/changed_value/orders.csv | wc -l)  (a line count alone would miss this)"
[ "$(md5sum < $LOCAL | cut -d' ' -f1)" == "$(hdfs dfs -cat $NEG/changed_value/orders.csv | md5sum | cut -d' ' -f1)" ] \
  && echo "   MD5 check:  PASS   <- test did NOT catch the error" || echo "   MD5 check:  FAIL   <- error detected (expected)"

echo "== N3: copy of the MapReduce 'late' output with ONE number changed (First Class late orders 9602 -> 9601)"
hdfs dfs -cat /datalake/curated/mapreduce/late/part-r-00000 | sed 's/^First Class,9602,9602/First Class,9602,9601/' \
  | hdfs dfs -put -f - $NEG/mr_late_bad/part-r-00000
hdfs dfs -cat $NEG/mr_late_bad/part-r-00000
echo "   (Hive comparison of this damaged output is in negative_test.hql)"
