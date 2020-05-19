#!/bin/bash 

# Notes on setting up docker-compose with a PG_DUMPFILE from a running instance.
#
# * Don't use the built-in ./install.sh — it assumes a new install. We have to hew our
#   own trail to do an upgrade.
# * assumes PG_DUMPFILE is in this directory

PROJECT_NAME=$(basename $(dirname $0))
PG_DUMPFILE=sentry-202005141000.dump

# launch the postgres container
docker-compose up -d postgres

# copy the database dump into the running postgresql container
docker cp ${PG_DUMPFILE} ${PROJECT_NAME}_postgres_1:/var/${PG_DUMPFILE}

# load the sentry database
docker-compose exec postgres psql -U postgres -c \
    "create user ferdinand superuser; create user rdsadmin superuser;" \
    && psql -U postgres -f /var/${PG_DUMPFILE} >/var/${PG_DUMPFILE}.log 2>&1

# copy out the log if you'd like to see the output
docker cp ${PROJECT_NAME}_postgres_1:/var/${PG_DUMPFILE}.log ${PG_DUMPFILE}.log 

# set up the .env file for our usage
echo SENTRY_SECRET_KEY="$(dkc run web config generate-secret-key)" >.env
echo SENTRY_DB_NAME=sentry >>.env
echo SENTRY_DB_USER=ferdinand >>.env

# start up the web container and copy in our migration patch(es)
docker-compose up -d web
docker cp \
    south_migrations.patch/* \
    ${PROJECT_NAME}_web_1:/usr/local/lib/python2.7/site-packages/sentry/south_migrations

# Use the web container to upgrade the database
docker-compose run web sentry upgrade
