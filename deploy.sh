#!/bin/bash
set -euo pipefail

# Netwerk
docker network inspect todo-net >/dev/null 2>&1 || docker network create todo-net

# Database: maken als ALS het nog niet bestaat.
if ! docker ps -a --format '{{.Names}}' | grep -qx todoappdb; then
  docker run -d --name todoappdb --network todo-net \
    -e MARIADB_ROOT_PASSWORD=sekrit \
    -e MARIADB_DATABASE=todo_db \
    -e MARIADB_USER=todo_usr \
    -e MARIADB_PASSWORD=letmeinplz \
    -v todo-db-data:/var/lib/mysql \
    mariadb:11
fi
docker start todoappdb >/dev/null

# Wachten tot database accepteert connectie
until docker exec todoappdb healthcheck.sh --connect --innodb_initialized; do
  echo "wachten voor database..."
  sleep 3
done

# Schema laden (piped van de Jenkins workspace via stdin)
docker exec -i todoappdb mariadb -utodo_usr -pletmeinplz todo_db < TodoApp/schema.sql

# App bouwen en (re)starten
docker build -t todoapp ./TodoApp
docker rm -f todoapp || true
docker run -d --name todoapp --network todo-net -p 8081:8080 \
  -e "ConnectionStrings__TodoDb=Server=todoappdb;Port=3306;Database=todo_db;User=todo_usr;Password=letmeinplz;" \
  -e ASPNETCORE_ENVIRONMENT=Development \
  todoapp

docker ps