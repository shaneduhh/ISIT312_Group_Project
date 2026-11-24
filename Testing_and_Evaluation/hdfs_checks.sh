#!/bin/bash
LOCAL=~/datalake_local
pass=0; fail=0
check() {
  if [ "$2" == "$3" ]; then echo "PASS  $1"; pass=$((pass+1)); else echo "FAIL  $1  (expected $2, got $3)"; fail=$((fail+1)); fi
}
for f in raw/DataCoSupplyChainDataset.csv raw/DescriptionDataCoSupplyChain.csv raw/tokenized_access_logs.csv \
         cleaned/items/DataCoSupplyChainDataset_cleaned.csv cleaned/orders/DataCoOrders_cleaned.csv; do
  name=$(basename $f)
  local_md5=$(md5sum < $LOCAL/$name | cut -d' ' -f1)
  hdfs_md5=$(hadoop fs -cat /datalake/$f | md5sum | cut -d' ' -f1)
  check "MD5   /datalake/$f" "$local_md5" "$hdfs_md5"
  check "Lines /datalake/$f" "$(wc -l < $LOCAL/$name)" "$(hadoop fs -cat /datalake/$f | wc -l)"
done
check "fsck /datalake is HEALTHY" "HEALTHY" "$(hdfs fsck /datalake 2>/dev/null | grep -o HEALTHY | head -1)"
echo "----"; echo "Passed: $pass   Failed: $fail"
