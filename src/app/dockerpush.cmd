

docker build --no-cache --tag=mapineqfrontend .

docker tag mapineqfrontend registry.webhosting.rug.nl/mapineq/mapineqfrontend:latest

docker push registry.webhosting.rug.nl/mapineq/mapineqfrontend:latest
