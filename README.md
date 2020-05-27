# Database-hasura 

Database-hasura is a postgres with hasura instance that manages data and access to it.

## Installation

* Use the [docker](https://www.docker.com) container service with docker-compose to install database-hasura.
* Use the [Hasura CLI](https://hasura.io/docs/1.0/graphql/manual/hasura-cli/install-hasura-cli.html#install-hasura-cli) to manage migration.

## Usage

* ```Dev``` configuration immediately starts the database snapshot and rolls all migrations.
* After launch, hasura console is available at [localhost:8081/console](localhost:8081/console), if it is not disabled in the configuration.
* The ```./hasura``` directory contains the initial configuration for ```hasura cli```.
* When working with the database through the ```hasura console```, the changes will be exported to the migration and metadata directory where the ```hasura cli``` was initialized.

### Hasura CLI

All commands must be executed in the ```./hasura``` directory or initialized a new directory.

* ```hasura init``` - Initialize directory for Hasura GraphQL Engine migrations, but you can use the existing ```.hasura``` directory. You will need to specify the configuration in the ```config.yaml``` file.

* ```hasura migrate create baseline --from-server``` - Exports a snapshot of the current database schema named ```baseline``` to the ```migrations``` directory.

* ```hasura metadata export``` - Exports the entire hasura metadata schema. The uploaded data is placed in the ```metadata``` directory.

* ```hasura console --console-port 8083``` - Runs hasura console on [localhost:8083/console](localhost:8083/console).

* ```hasura migrate create <name-of-migration>``` - Create sql and yaml files required for a migration.

* ```hasura migrate squash --name "<feature-name>" --from <migration-version>``` - Squash multiple migrations leading upto the latest one into a single migration file.

* ```hasura migrate apply --endpoint <server-endpoint>``` - Apply migrations on the database.

* ```hasura metadata apply --endpoint <server-endpoint>``` - Apply Hasura metadata on a database.

* ```hasura migrate status``` - Display current status of migrations on a database.

## Dev

Build or rebuild services:
```
docker-compose -f docker-compose.yaml -f docker-compose.dev.yaml build
```
Builds, (re)creates, starts, and attaches to containers for a service:
```
docker-compose -f docker-compose.yaml -f docker-compose.dev.yaml up -d
```

![#f03c15](https://via.placeholder.com/15/f03c15/000000?text=+) Danger zone!

Stops containers and removes containers, networks, volumes, and images
created by `up`.

* Not for production!

```diff
- docker-compose -f docker-compose.yaml -f docker-compose.dev.yaml down -v
```

## Prod

Just builds, (re)creates, starts, and attaches to containers for a service:

```
docker-compose -f docker-compose.yaml -f docker-compose.prod.yaml up -d
```
