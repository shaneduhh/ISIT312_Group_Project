#!/bin/bash
# ISIT312 Big Data Project - Member 8: Hive and HQL
# Step 1-3: check the Hive install, the Metastore and the link to HDFS.
# Safe to re-run: it only checks and creates folders, it never deletes anything.

echo "== 1. Versions =="
hadoop version | head -1
hive --version 2>/dev/null | head -1

echo "== 2. Hadoop services (expect NameNode, DataNode, ResourceManager, NodeManager) =="
jps

echo "== 3. HDFS address Hive will use (expect hdfs://localhost:8020) =="
hdfs getconf -confKey fs.defaultFS

echo "== 4. Hive scratch and warehouse folders on HDFS =="
hadoop fs -mkdir -p /tmp /user/hive/warehouse
hadoop fs -chmod g+w /tmp /user/hive/warehouse
hadoop fs -ls -d /tmp /user/hive/warehouse

echo "== 5. Member 6's Data Lake folders and the cleaned files =="
hadoop fs -ls -R /datalake/cleaned
hadoop fs -ls /datalake/curated

echo "== 6. Metastore status =="
# Prints the schema version if the Metastore is already set up.
# If it says the schema is missing, run ONCE (from your Hive working folder):
#   schematool -dbType derby -initSchema
schematool -dbType derby -info 2>&1 | tail -5
