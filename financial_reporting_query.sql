"""Run the reporting SQL query and save the result as a dated Excel file."""

from __future__ import annotations

import os
from datetime import datetime
from pathlib import Path

import pandas as pd
import pyodbc


def required_env(name: str) -> str:
    """Return a required environment variable or raise a clear error."""
    value = os.getenv(name, "").strip()
    if not value:
        raise RuntimeError(f"Missing required environment variable: {name}")
    return value


def build_connection_string() -> str:
    """Build an interactive Microsoft Entra ID connection string."""
    server = required_env("REPORTING_SQL_SERVER")
    database = required_env("REPORTING_SQL_DATABASE")
    driver = os.getenv("REPORTING_ODBC_DRIVER", "ODBC Driver 18 for SQL Server")

    return (
        f"DRIVER={{{driver}}};"
        f"SERVER={server};"
        f"DATABASE={database};"
        "Authentication=ActiveDirectoryInteractive;"
        "Encrypt=yes;TrustServerCertificate=no;"
    )


def main() -> None:
    sql_path = Path(required_env("REPORTING_SQL_FILE")).expanduser()
    output_folder = Path(required_env("REPORTING_OUTPUT_FOLDER")).expanduser()

    if not sql_path.is_file():
        raise FileNotFoundError(f"SQL file not found: {sql_path}")

    output_folder.mkdir(parents=True, exist_ok=True)
    sql_query = sql_path.read_text(encoding="utf-8")

    print("Connecting to the reporting database...")
    with pyodbc.connect(build_connection_string(), timeout=30) as connection:
        print("Running query...")
        report_data = pd.read_sql_query(sql_query, connection)

    if report_data.empty:
        raise RuntimeError("The query completed but returned no rows.")

    run_date = datetime.now().strftime("%Y%m%d")
    output_path = output_folder / f"financial_report_{run_date}.xlsx"
    report_data.to_excel(output_path, index=False)

    print(f"Rows returned: {len(report_data):,}")
    print(f"Report saved: {output_path}")


if __name__ == "__main__":
    main()
