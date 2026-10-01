-- Runs once, the first time the MySQL container starts (empty data volume).
-- Metabase gets its own read-only user: dashboards can read the data but never change it.
CREATE USER IF NOT EXISTS 'metabase_ro'@'%' IDENTIFIED BY 'metabase_ro';
GRANT SELECT, SHOW VIEW ON ad_kpi.* TO 'metabase_ro'@'%';
FLUSH PRIVILEGES;
