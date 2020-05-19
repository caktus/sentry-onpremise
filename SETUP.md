Notes on setting up docker-compose with a PG_DUMPFILE from a running instance.

```bash
#!/bin/bash

PG_DUMPFILE=sentry-202005141000.dump

docker-compose up -d postgres
docker-compose logs -f     # wait until postgres is ready, then Ctrl+C and continue:

docker-compose exec postgres psql -U postgres \
    -c "create user ferdinand superuser; create user rdsadmin superuser;"

cp ${PG_DUMPFILE} data/sentry/${PG_DUMPFILE}
docker-compose exec postgres bash
psql -U postgres \
    -f /var/lib/sentry/files/${PG_DUMPFILE} \
    >/var/lib/sentry/files/${PG_DUMPFILE}.log 2>&1

docker-compose up -d; docker-compose logs -f    # ensure that all is working, then Ctrl+C

docker-compose exec web sentry createuser   # create a new superuser for yourself, if needed
```