#!/bin/bash
# Notes on setting up docker-compose with a PG_DUMPFILE from a running instance.

# Don't use the built-in ./install.sh — it assumes a new install. We have to hew our own
# trail to do an upgrade.

# assumes PG_DUMPFILE is in the sentry-onpremise directory
PG_DUMPFILE=sentry-202005141000.dump

# launch the postgres container
docker-compose up -d postgres

# copy the database dump into the running postgresql container
docker cp ${PG_DUMPFILE} sentry-onpremise_postgres_1:/var/${PG_DUMPFILE}

# load the sentry database
docker-compose exec postgres psql -U postgres -c \
    "create user ferdinand superuser; create user rdsadmin superuser;" \
    && psql -U postgres -f /var/${PG_DUMPFILE} >/var/${PG_DUMPFILE}.log 2>&1

# copy out the log if you'd like to see the output
docker cp sentry-onpremise_postgres_1:/var/${PG_DUMPFILE}.log ${PG_DUMPFILE}.log 

# set up the .env file for our usage
echo SENTRY_SECRET_KEY="$(dkc run web config generate-secret-key)" >.env
echo SENTRY_DB_NAME=sentry >>.env
echo SENTRY_DB_USER=ferdinand >>.env

# Use the web container to upgrade the database -- NOT WORKING
docker-compose run web sentry upgrade
