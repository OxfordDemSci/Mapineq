

docker build --no-cache --tag=mapineqfrontendfirst .

docker tag mapineqfrontendfirst registry.webhosting.rug.nl/mapineq/mapineqfrontendfirst:latest

docker push registry.webhosting.rug.nl/mapineq/mapineqfrontendfirst:latest
