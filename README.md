# ski-bookstack
ski wiki

## Overview

This project runs [BookStack](https://www.bookstackapp.com/) — an open-source, self-hosted wiki and documentation platform — using Docker Compose. It is configured to avoid port conflicts with other local services (port 8090 is used instead of 8080).

---

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed and running
- [Docker Compose](https://docs.docker.com/compose/install/) v2 or later (`docker compose` command)

---

## Setup

### 1. Clone the repository

```bash
git clone <your-repo-url>
cd ski-bookstack
git checkout feature/init-docker
```

### 2. Configure environment variables

Copy the example environment file and fill in your own values:

```bash
cp .env.example .env
```

Generate a required application key first (Docker must be running):

```bash
docker run -it --rm --entrypoint /bin/bash lscr.io/linuxserver/bookstack:latest appkey
```

This outputs a value like `APP_KEY=base64:xxxx...`. Copy it, then open `.env` and fill in all values:

```env
TZ=America/New_York          # Your local timezone
APP_URL=http://localhost:8090 # URL you will access BookStack from
APP_KEY=base64:xxxx...       # Paste the generated key here — required, app won't start without it

DB_DATABASE=bookstack
DB_USER=bookstack
DB_PASS=your_bookstack_db_password    # Choose a strong password
DB_ROOT_PASS=your_mariadb_root_password  # Choose a strong root password
```

> **Never commit `.env` to version control.** It is already listed in `.gitignore`.

---

## Running BookStack

### Start the stack

```bash
docker compose up -d
```

This will:
- Pull the `lscr.io/linuxserver/bookstack` and `lscr.io/linuxserver/mariadb` images
- Start the MariaDB database container (`bookstack_db`)
- Wait for the database to be healthy, then start the BookStack container (`bookstack`)
- Expose BookStack at **http://localhost:8090**

### First login

Open your browser and go to:

```
http://localhost:8090
```

Default credentials:
| Field | Value |
|-------|-------|
| Email | `admin@admin.com` |
| Password | `password` |

**Change your password immediately after first login.**

---

## Verifying the Database

Use these checks to confirm MariaDB is running and the credentials in your `.env` are correct.

### Check the container is healthy

```bash
docker compose ps
```

The `bookstack_db` container should show `healthy` in the Status column:

```
NAME            STATUS
bookstack       running
bookstack_db    running (healthy)
```

### Connect to the database directly

Log in using the credentials from your `.env`:

```bash
docker exec -it bookstack_db mariadb -u bookstack -p bookstack
```

Enter `DB_PASS` when prompted. A successful login looks like:

```
Welcome to the MariaDB monitor. Commands end with ; or \g.
MariaDB [bookstack]>
```

Type `exit` to quit.

### Verify the bookstack database and tables exist

After BookStack has started at least once, it runs migrations and creates all its tables. Confirm they are present:

```bash
docker exec -it bookstack_db mariadb -u bookstack -p bookstack -e "SHOW TABLES;"
```

Expected output includes tables such as `users`, `books`, `pages`, `chapters`, etc. An empty result means BookStack has not yet run its migrations — check the BookStack logs.

### Test the root password

```bash
docker exec -it bookstack_db mariadb -u root -p -e "SHOW DATABASES;"
```

Enter `DB_ROOT_PASS` when prompted. You should see `bookstack` listed among the databases:

```
+--------------------+
| Database           |
+--------------------+
| bookstack          |
| information_schema |
| mysql              |
+--------------------+
```

### Test connectivity from the BookStack container

Confirm the BookStack container can reach the database over the internal network:

```bash
docker exec -it bookstack mariadb-admin ping -h bookstack_db -u bookstack -p
```

A working connection returns:

```
mysqld is alive
```

---

## Verifying BookStack

Use these checks to confirm the application is running and reachable.

### Check the HTTP response

```bash
curl -o /dev/null -s -w "HTTP status: %{http_code}\n" http://localhost:8090
```

A healthy BookStack returns `HTTP status: 200`. Any other code indicates a startup problem — check logs with `docker compose logs -f bookstack`.

### Confirm the login page loads

```bash
curl -s http://localhost:8090/login | grep -o "<title>.*</title>"
```

Expected output:

```
<title>Login | BookStack</title>
```

### Verify BookStack startup in logs

```bash
docker compose logs bookstack | grep -E "Server running|migrations|error" | tail -20
```

A clean startup shows lines like:

```
bookstack  | [migrations] Migration table created successfully.
bookstack  | [migrations] Migrated: xxxx_xx_xx_xxxxxx_create_users_table
...
bookstack  | Server running on http://0.0.0.0:80
```

Any `error` lines in the output need investigation.

### Test the BookStack API

BookStack exposes a REST API. After logging in and generating a token under **Profile → API Tokens**, you can verify the API is alive:

```bash
curl -s \
  -H "Authorization: Token YOUR_TOKEN_ID:YOUR_TOKEN_SECRET" \
  http://localhost:8090/api/books | python3 -m json.tool
```

A working API returns a JSON object with a `data` array. Before creating an API token, you can confirm the endpoint exists with:

```bash
curl -o /dev/null -s -w "API status: %{http_code}\n" http://localhost:8090/api/books
```

This returns `API status: 401` (unauthorized) if the API is reachable, or `000` if the app is not running.

### Run the BookStack built-in health check

```bash
docker exec -it bookstack php /app/www/artisan bookstack:check-config
```

This validates the full configuration — database connection, mail settings, app key, and more — and reports any problems.

---

## Managing the Stack

### View running containers

```bash
docker compose ps
```

### View logs

```bash
# All containers
docker compose logs -f

# BookStack only
docker compose logs -f bookstack

# Database only
docker compose logs -f bookstack_db
```

### Stop the stack

```bash
docker compose down
```

### Stop and remove all data (full reset)

```bash
docker compose down -v
```

> This permanently deletes all BookStack content and database data.

### Restart after a configuration change

```bash
docker compose down
docker compose up -d
```

---

## Data Persistence

All data is stored in named Docker volumes:

| Volume | Contents |
|--------|----------|
| `bookstack_data` | BookStack uploads, config, and app files |
| `bookstack_db_data` | MariaDB database files |

These volumes survive `docker compose down` and are only removed with `docker compose down -v`.

---

## Ports

| Service | Container Port | Host Port |
|---------|---------------|-----------|
| BookStack | 80 | **8090** |
| MariaDB | 3306 | *(internal only)* |

Port 8090 was chosen because port 8080 is already in use on the host machine.

---

## Troubleshooting

**`Access denied for user 'database_username'`:**
Your `.env` file still contains placeholder values from `.env.example`. Open `.env`, replace every placeholder with real values, then wipe the database volume and restart — the old credentials are baked into the volume and will persist until it is removed:
```bash
docker compose down -v
docker compose up -d
```
> Do not skip `-v`. Without it the old credentials remain and the error repeats.

**BookStack shows a database connection error on first start:**
The database may still be initializing. Wait 30–60 seconds and refresh.

**`500 Internal Server Error` in the browser:**
Check the logs in this order:

1. Container logs (quickest overview):
```bash
docker compose logs bookstack --tail=50
```

2. Laravel application log (most detailed — full stack traces):
```bash
docker exec -it bookstack tail -100 /config/log/bookstack/laravel.log
```

3. Built-in config validator (checks APP_KEY, DB, permissions in one pass):
```bash
docker exec -it bookstack php /app/www/artisan bookstack:check-config
```

Common causes and fixes:

| Log message | Cause | Fix |
|---|---|---|
| `The MAC is invalid` / `DecryptException` | `APP_KEY` changed after first boot | Restore original key, or wipe volumes and restart |
| `SQLSTATE[HY000] [1045] Access denied` | Wrong DB credentials | Fix `.env`, then `docker compose down -v && docker compose up -d` |
| `SQLSTATE[HY000] [2002] Connection refused` | DB not ready or crashed | `docker compose restart bookstack_db`, then `docker compose restart bookstack` |
| `No application encryption key` | `APP_KEY` missing from `.env` | Generate a key and add it (see Setup section) |
| `Permission denied` on storage/cache | Volume ownership issue | `docker exec -it bookstack chown -R abc:abc /config` then restart |

If none of the above resolves it, wipe all volumes and start clean:
```bash
docker compose down -v
docker compose up -d
```

**Containers won't start:**
Check for port conflicts or missing `.env` values:
```bash
docker compose logs
```

**Forgot your admin password:**
Reset it from within the BookStack container:
```bash
docker exec -it bookstack php /app/www/artisan bookstack:reset-admin-password
```

