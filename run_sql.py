"""Run a .sql file against the MySQL database and print the result of every query.

Usage:  python run_sql.py sql/00_load.sql

Connection settings come from environment variables (see .env.example);
the defaults match docker-compose.yml.
"""
import os
import sys
from pathlib import Path

import pymysql
from tabulate import tabulate

PROJECT_ROOT = Path(__file__).parent


def load_env_file() -> None:
    """Read KEY=VALUE pairs from .env, if present, without overriding real env vars."""
    env_file = PROJECT_ROOT / ".env"
    if env_file.exists():
        for line in env_file.read_text().splitlines():
            if "=" in line and not line.lstrip().startswith("#"):
                key, value = line.split("=", 1)
                os.environ.setdefault(key.strip(), value.strip())


def split_statements(sql: str) -> list[str]:
    """Drop full-line -- comments, then split on semicolons."""
    lines = [line for line in sql.splitlines() if not line.strip().startswith("--")]
    return [stmt.strip() for stmt in "\n".join(lines).split(";") if stmt.strip()]


def run(sql_file: str) -> None:
    sql = Path(sql_file).read_text()
    load_env_file()
    os.chdir(PROJECT_ROOT)  # so relative paths like data/... resolve
    con = pymysql.connect(
        host=os.getenv("MYSQL_HOST", "127.0.0.1"),
        port=int(os.getenv("MYSQL_PORT", "3306")),
        user=os.getenv("MYSQL_USER", "analyst"),
        password=os.getenv("MYSQL_PASSWORD", "analyst"),
        database=os.getenv("MYSQL_DATABASE", "ad_kpi"),
        local_infile=True,
        autocommit=True,
    )
    with con, con.cursor() as cur:
        for statement in split_statements(sql):
            cur.execute(statement)
            if cur.description:  # only queries that return rows
                headers = [col[0] for col in cur.description]
                print(tabulate(cur.fetchall(), headers=headers, tablefmt="psql",
                               floatfmt=".2f"))
                print()


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("Usage: python run_sql.py <path/to/file.sql>")
    run(sys.argv[1])
