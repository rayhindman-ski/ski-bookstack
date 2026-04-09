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

Open `.env` and set secure passwords:

```env
TZ=America/New_York          # Your local timezone
APP_URL=http://localhost:8090 # URL you will access BookStack from

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

**BookStack shows a database connection error on first start:**
The database may still be initializing. Wait 30–60 seconds and refresh.

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

