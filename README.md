```text
├── Dataset_Analysis_and_Cleaning/
│   ├── DataCo_Data_Dictionary.csv       # Schema definitions and field descriptions
│   ├── Member_3_Analysis.ipynb          # Exploratory Data Analysis (EDA) notebook
│   └── member_4_cleaning.py             # Python ETL data cleansing & standardization script
├── Hive_Analytics/
│   ├── 00_check_environment.sh          # Hadoop, HDFS, and Hive service verification
│   ├── 01_create_database_tables.hql    # Hive database and external/managed table DDL
│   ├── 02_validate_tables.hql           # Row-count and schema integrity validation
│   ├── 03_analysis_queries.hql          # Core supply chain & profitability BI queries
│   ├── 04_export_results.hql            # Curated query output export scripts
│   └── expected_results/                # Reference CSV outputs for validation & Q1–Q5
└── Testing_and_Evaluation/
    ├── hdfs_checks.sh                   # HDFS directory, block health, and checksum checks
    ├── member9_checks.hql               # Hive data quality and assertion checks
    ├── negative_test.sh                 # Fault-handling shell test runner
    ├── negative_test.hql                # Fault-handling HQL edge-case queries
    └── timing.sh                        # Query execution runtime benchmarking script
