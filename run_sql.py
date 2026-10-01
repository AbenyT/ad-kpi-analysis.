"""Run a .sql file against ads.duckdb and print the result of every query.

Usage:  python run_sql.py sql/00_load.sql
"""
import sys
from pathlib import Path

import duckdb

DB_PATH = Path(__file__).parent / "ads.duckdb"


def run(sql_file: str) -> None:
    sql = Path(sql_file).read_text()
    with duckdb.connect(str(DB_PATH)) as con:
        for statement in con.extract_statements(sql):
            result = con.sql(statement.query)
            if result is not None:  # SELECTs return a relation, DDL returns None
                result.show(max_width=200)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("Usage: python run_sql.py <path/to/file.sql>")
    run(sys.argv[1])
