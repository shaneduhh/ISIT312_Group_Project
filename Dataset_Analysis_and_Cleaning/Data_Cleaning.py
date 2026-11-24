"""
ISIT312 Big Data Project - Member 4: Data Cleaning and Technical Preparation
Aligned with Member 3's Dataset Analysis & DataCo_Data_Dictionary.csv
"""

from pathlib import Path
from zipfile import ZipFile
from io import BytesIO
import hashlib
import re
import pandas as pd

# 1. Verify raw files against Mendeley V5 SHA-256 hashes (leaving raw files unchanged)
EXPECTED_HASHES = {
    "DataCoSupplyChainDataset.csv": "fa6d022ed437155e1a2f0378710602848703c8a7f203f7ff5d77805bf8480aa6",
    "DescriptionDataCoSupplyChain.csv": "9828e34669bd6d77e3b4463364cc44a5d52446b5e246fc258758cfe592566c4b",
    "tokenized_access_logs.csv": "7a4372df63a1e87f5add68bc036bb6064db09069998f25a679aec39f1a8d7765",
}

CLEANED_ITEMS_FILE = "DataCoSupplyChainDataset_cleaned.csv"
CLEANED_ORDERS_FILE = "DataCoOrders_cleaned.csv"


def load_verified_source(filename: str, **kwargs) -> pd.DataFrame:
    raw_dir = next(
        (
            p
            for p in [Path("raw"), Path(".")]
            if all((p / name).is_file() for name in EXPECTED_HASHES)
        ),
        None,
    )
    archive = Path("DataCo_Original_Files.zip")
    if raw_dir is not None:
        raw_bytes = (raw_dir / filename).read_bytes()
    elif archive.is_file():
        with ZipFile(archive) as zf:
            raw_bytes = zf.read(filename)
    else:
        raise FileNotFoundError(
            f"Place {filename} in './raw/', '.', or inside 'DataCo_Original_Files.zip'."
        )

    actual_hash = hashlib.sha256(raw_bytes).hexdigest()
    assert actual_hash == EXPECTED_HASHES[filename], f"SHA-256 mismatch for {filename}"
    return pd.read_csv(
        BytesIO(raw_bytes),
        encoding="latin1",
        keep_default_na=False,
        na_values=[""],
        **kwargs,
    )


def to_snake_case(col: str) -> str:
    col = re.sub(r"[()]", "", col.strip())
    col = re.sub(r"[\s\-]+", "_", col)
    return col.lower()


def main() -> None:
    print("Step 1: Reading and verifying original DataCoSupplyChainDataset.csv...")
    df = load_verified_source(
        "DataCoSupplyChainDataset.csv",
        dtype={"Customer Zipcode": "string", "Order Zipcode": "string"},
    )
    print(f"  Verified raw shape: {len(df):,} rows x {df.shape[1]} columns")

    # Step 2: Verify duplicate records before cleaning
    assert df.duplicated().sum() == 0, "Unexpected exact duplicate rows found"
    assert df["Order Item Id"].duplicated().sum() == 0, "Duplicate Order Item Id found"

    # Step 3: Remove columns per Member 3's Data Dictionary & Report
    # - 7 fields marked 'Omit from analytical view':
    omit_fields = [
        "Product Description",  # 100% missing (180,519 rows)
        "Customer Email",       # Constant masked string
        "Customer Password",    # Constant masked string
        "Customer Fname",       # PII not needed for supply-chain analytics
        "Customer Lname",       # PII (8 missing rows) not needed
        "Customer Street",      # PII street address not needed
        "Product Image",        # External URL string
    ]
    # - 1 constant field with zero variation:
    constant_fields = [
        "Product Status",       # Constant 0 across all 180,519 rows
    ]
    # - 5 verified duplicate alias fields (retaining Member 3's preferred column from each pair):
    alias_fields = [
        "Benefit per order",      # Matches 'Order Profit Per Order' (0 differences)
        "Sales per customer",     # Matches 'Order Item Total' (0 differences)
        "Product Category Id",    # Matches 'Category Id' (0 differences)
        "Order Customer Id",      # Matches 'Customer Id' (0 differences)
        "Order Item Cardprod Id", # Matches 'Product Card Id' (0 differences)
    ]

    cols_to_drop = omit_fields + constant_fields + alias_fields
    df.drop(columns=cols_to_drop, inplace=True)
    print(f"Step 2: Dropped {len(cols_to_drop)} omitted/constant/alias columns -> {df.shape[1]} columns retained.")

    # Step 4: Parse and standardize timestamps to ISO-8601 (YYYY-MM-DD HH:MM:SS)
    fmt = "%m/%d/%Y %H:%M"
    for raw_col in ["order date (DateOrders)", "shipping date (DateOrders)"]:
        parsed = pd.to_datetime(df[raw_col], format=fmt, errors="raise")
        df[raw_col] = parsed.dt.strftime("%Y-%m-%d %H:%M:%S")

    # Rename headers to clean snake_case for Hive and MapReduce compatibility
    df.columns = [to_snake_case(c) for c in df.columns]
    df.rename(
        columns={
            "order_date_dateorders": "order_date",
            "shipping_date_dateorders": "shipping_date",
        },
        inplace=True,
    )

    # Step 5: Preserve nullable postal codes as clean text (leave missing values blank "")
    for zip_col in ["customer_zipcode", "order_zipcode"]:
        df[zip_col] = df[zip_col].fillna("").astype(str).str.strip()

    # Step 6: Sanitize text fields so embedded commas/newlines do not break MapReduce/Hive CSV splits
    text_cols = df.select_dtypes(include=["object", "string"]).columns
    for col in text_cols:
        df[col] = (
            df[col]
            .fillna("")
            .astype(str)
            .str.replace(",", " -", regex=False)
            .str.replace(r"[\r\n]+", " ", regex=True)
            .str.strip()
        )

    # Step 7: Enforce numeric types and round IEEE-754 float precision noise
    float_cols = [
        "latitude",
        "longitude",
        "order_item_discount",
        "order_item_discount_rate",
        "order_item_product_price",
        "order_item_profit_ratio",
        "sales",
        "order_item_total",
        "order_profit_per_order",
        "product_price",
    ]
    for col in float_cols:
        df[col] = pd.to_numeric(df[col], errors="raise").round(4)

    int_cols = [
        "days_for_shipping_real",
        "days_for_shipment_scheduled",
        "late_delivery_risk",
        "category_id",
        "customer_id",
        "department_id",
        "order_id",
        "order_item_id",
        "order_item_quantity",
        "product_card_id",
    ]
    for col in int_cols:
        df[col] = pd.to_numeric(df[col], errors="raise").astype(int)

    # Step 8: Export cleaned item-level dataset (180,519 rows x 40 columns)
    df.to_csv(CLEANED_ITEMS_FILE, index=False, encoding="utf-8")
    print(f"Step 3: Exported item-level dataset '{CLEANED_ITEMS_FILE}' ({len(df):,} rows x {df.shape[1]} cols).")

    # Step 9: Export deduplicated order-level dataset (65,752 orders) for delivery-rate analysis
    order_cols = [
        "order_id",
        "order_date",
        "shipping_date",
        "shipping_mode",
        "delivery_status",
        "late_delivery_risk",
        "days_for_shipping_real",
        "days_for_shipment_scheduled",
        "order_status",
        "customer_id",
        "customer_segment",
        "market",
        "order_region",
        "order_country",
        "order_state",
        "order_city",
        "order_zipcode",
    ]
    orders_df = df[order_cols].drop_duplicates(subset=["order_id"]).copy()
    orders_df.to_csv(CLEANED_ORDERS_FILE, index=False, encoding="utf-8")
    print(f"Step 4: Exported order-level dataset '{CLEANED_ORDERS_FILE}' ({len(orders_df):,} unique orders).")

    # Step 10: Verify cleaned data reproduces Member 3's benchmark outputs
    eligible = orders_df[
        orders_df["delivery_status"].isin(
            ["Advance shipping", "Shipping on time", "Late delivery"]
        )
    ]
    assert len(eligible) == 62897 and eligible["late_delivery_risk"].sum() == 36048
    completed = df[df["order_status"] == "COMPLETE"]
    fishing_profit = completed.loc[
        completed["category_id"] == 45, "order_profit_per_order"
    ].sum()
    assert round(fishing_profit, 2) == 248022.93
    print("Step 5: Verification passed! Cleaned datasets match Member 3's benchmark figures.")

    print("\n--- CLEANED ITEM TABLE COLUMN INDEX MAP (40 COLUMNS) ---")
    for idx, col in enumerate(df.columns):
        print(f"Index {idx:2d}: {col} ({df[col].dtype})")


if __name__ == "__main__":
    main()
