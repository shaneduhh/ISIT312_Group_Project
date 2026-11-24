#!/bin/bash
cd ~/member9/mapreduce
export HADOOP_CLIENT_OPTS="-Xmx2g"
printf "%-38s %8s\n" "Step" "Seconds"
for j in "SalesJob items sales" "ProfitJob items profit" "LateJob orders late" "ShippingJob orders shipping"; do
  set -- $j
  hdfs dfs -rm -r -f /datalake/curated/mapreduce/$3 >/dev/null 2>&1
  start=$(date +%s.%N)
  hadoop jar member9_mr.jar $1 /datalake/cleaned/$2/ /datalake/curated/mapreduce/$3 >/dev/null 2>&1
  status=$?
  printf "%-38s %8.1f %s\n" "MapReduce $1" "$(awk -v a=$start -v b=$(date +%s.%N) 'BEGIN{print b-a}')" "$([ $status -eq 0 ] && echo OK || echo FAILED)"
done
for q in q1_sales_by_category q2b_late_delivery_by_mode q3_shipping_time_by_region q4_top10_products q5_profit_by_category; do
  start=$(date +%s.%N)
  hive -S -e "USE dataco_dl; SELECT * FROM $q;" >/dev/null 2>&1
  status=$?
  printf "%-38s %8.1f %s\n" "Hive $q" "$(awk -v a=$start -v b=$(date +%s.%N) 'BEGIN{print b-a}')" "$([ $status -eq 0 ] && echo OK || echo FAILED)"
done
