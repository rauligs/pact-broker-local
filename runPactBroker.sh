#!/usr/bin/env bash

function rm_docker() {
	if docker ps -a | grep ${1}; then
  		echo ">> Removing -->"
  		docker stop ${1}
  		docker rm ${1}
	fi
}

rm_docker pactbroker-db
rm_docker pactbroker

echo ">> Docker run pactbroker-db"
docker run --name pactbroker-db -e POSTGRES_PASSWORD=ThePostgresPassword -e POSTGRES_USER=admin -e PGDATA=/var/lib/postgresql/data/pgdata -v /var/lib/postgresql/data:/var/lib/postgresql/data -d postgres

echo ">> Resetting pactbroker-db"
docker run -it --link pactbroker-db:postgres -e PGPASSWORD=ThePostgresPassword --rm postgres sh -c 'exec psql -h "$POSTGRES_PORT_5432_TCP_ADDR" -p "$POSTGRES_PORT_5432_TCP_PORT" -U admin -c "DROP DATABASE IF EXISTS pactbroker"'
docker run -it --link pactbroker-db:postgres -e PGPASSWORD=ThePostgresPassword --rm postgres sh -c 'exec psql -h "$POSTGRES_PORT_5432_TCP_ADDR" -p "$POSTGRES_PORT_5432_TCP_PORT" -U admin -c "DROP USER IF EXISTS pactbrokeruser"'

echo ">> Create user"
docker run -it --link pactbroker-db:postgres -e PGPASSWORD=ThePostgresPassword --rm postgres sh -c 'exec psql -h "$POSTGRES_PORT_5432_TCP_ADDR" -p "$POSTGRES_PORT_5432_TCP_PORT" -U admin -c "CREATE USER pactbrokeruser WITH PASSWORD '\''TheUserPassword'\''"'

echo ">> Create db"
docker run -it --link pactbroker-db:postgres -e PGPASSWORD=ThePostgresPassword --rm postgres sh -c 'exec psql -h "$POSTGRES_PORT_5432_TCP_ADDR" -p "$POSTGRES_PORT_5432_TCP_PORT" -U admin -c "CREATE DATABASE pactbroker WITH OWNER pactbrokeruser"'

echo ">> Granting privileges"
docker run -it --link pactbroker-db:postgres -e PGPASSWORD=ThePostgresPassword --rm postgres sh -c 'exec psql -h "$POSTGRES_PORT_5432_TCP_ADDR" -p "$POSTGRES_PORT_5432_TCP_PORT" -U admin -c "GRANT ALL PRIVILEGES ON DATABASE pactbroker TO pactbrokeruser;"'

echo ">> Docker run pactbroker"
docker run --name pactbroker --link pactbroker-db:postgres -e PACT_BROKER_DATABASE_USERNAME=pactbrokeruser -e PACT_BROKER_DATABASE_PASSWORD=TheUserPassword -e PACT_BROKER_DATABASE_HOST=postgres -e PACT_BROKER_DATABASE_NAME=pactbroker -d -p 80:80 dius/pact-broker
