-- Runs once, the first time the MySQL container starts (empty data volume).
-- Metabase gets its own read-only user: dashboards can read the data but never change it.
--
-- mysql_native_password: MySQL 8's default (caching_sha2_password) needs an RSA key exchange
-- on non-SSL connections, which Metabase's driver does not do by default
-- ("RSA public key is not available client side"). Fine for a local, read-only user.
CREATE USER IF NOT EXISTS 'metabase_ro'@'%' IDENTIFIED WITH mysql_native_password BY 'metabase_ro';
GRANT SELECT, SHOW VIEW ON ad_kpi.* TO 'metabase_ro'@'%';
FLUSH PRIVILEGES;
