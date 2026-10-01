# Run the database and Metabase dashboard locally

Tested with Docker Compose, MySQL 8.0 and Metabase v0.63.19.

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (running)
- Python 3.10+
- About 3 GB of free disk space for the two Docker images

## 1. Get the project and install Python packages

macOS / Linux:

```bash
git clone https://github.com/AbenyT/ad-kpi-analysis.git
cd ad-kpi-analysis
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Windows (PowerShell):

```powershell
git clone https://github.com/AbenyT/ad-kpi-analysis.git
cd ad-kpi-analysis
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

## 2. Start MySQL and Metabase

```bash
docker compose up -d
docker compose ps
```

Wait until `ad_kpi_mysql` shows `(healthy)`. The first start downloads the images and can take a few minutes.

## 3. Build the database

```bash
python run_sql.py sql/*.sql
```

This runs `00_load.sql` to `09_views.sql` in order: load, check, clean, KPIs and views.
The last tables printed should show every view with `58705.23` spend and `1079` approved conversions.

## 4. Set up Metabase

Open **http://localhost:3000**. Metabase needs about 1 minute after `docker compose up` before the page loads.

1. **Welcome to Metabase:** click **Let's get started**.
2. **What should we call you?** Fill in first name, last name, email, company or team name (for example `Ad KPI Analysis`) and a password. Click **Next**.
   This creates your admin account immediately. If you leave the wizard after this point, sign in with this email and password and add the database from **Admin settings → Databases → Add database**, using the details in step 4.
3. **What will you use Metabase for?** Choose **Self-service analytics for my own company**. Click **Next**.
4. **Add your data:** click **MySQL** and fill in:

   | Field | Value |
   |---|---|
   | Display name | `Ad KPI (MySQL)` |
   | Host | `mysql` (the Docker service name, not `localhost`) |
   | Port | `3306` |
   | Database name | `ad_kpi` |
   | Username | `metabase_ro` |
   | Password | `metabase_ro` |

   Leave the other fields as they are and click **Connect database**.
5. **Usage data preferences:** choose whether to allow anonymous usage events, then click **Finish**.
6. **You're all set up!** Click **Take me to Metabase**.

The home page should list `Ad KPI (MySQL)` with the views `V Kpi Overall`, `V Kpi Campaign`, `V Kpi Age`, `V Kpi Gender`, `V Kpi Interest`, `V Kpi Segment` and `V Ads`.

`metabase_ro` is a read-only user: Metabase can read the data but cannot change it.

## Daily use

```bash
docker compose up -d     # start
docker compose down      # stop (data and Metabase settings are kept)
docker compose down -v   # reset everything (deletes the database and Metabase settings)
```

## Troubleshooting

| Problem | Fix |
|---|---|
| `port is already allocated` for 3306 | Another MySQL is running. Copy `.env.example` to `.env`, set `MYSQL_PORT=3307`, then run `docker compose up -d` again. `run_sql.py` reads the same setting. |
| Metabase: `Could not connect to address=(host=localhost)...` | Use host `mysql`, not `localhost`. Metabase runs inside Docker and reaches MySQL by its service name. |
| Metabase: `RSA public key is not available client side` | The MySQL volume was created before `docker/mysql-init` existed. Run `docker compose down -v`, `docker compose up -d` and step 3 again. |
| `toomanyrequests` / `429` when downloading images | Docker Hub's anonymous download limit. Run `docker login` with a free Docker account, or wait and retry. |
| Page at localhost:3000 does not load | Metabase is still starting. Check with `docker compose logs -f metabase` and wait for `Metabase Initialization COMPLETE`. |
