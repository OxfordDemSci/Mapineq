# Dockerfile used by the mapineq_db container
FROM postgis/postgis:latest

RUN apt-get update -y
RUN apt-get -y install curl

CMD ["postgres", "-c", "config_file=/db/postgresql.conf"]
# CMD ["sleep", "3600"]