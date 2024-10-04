  The file daemon.json allows you to define the storage location for docker images, including the postgresql data volume.
  This can be used to move the SQL data to an attached storage with more disk space.

  The process for relocating the docker data storage location is as follows:
  1. Stop the docker service:  sudo service docker stop
  2. Copy daemon.json to the correct location:  sudo cp ~/MapIneq/src/daemon.json /etc/docker/daemon.json
  3. Copy the docker data to the new location:  sudo rsync -aP /var/lib/docker/ /data/docker/
  4. Rename the old data location:  sudo mv /var/lib/docker /var/lib/docker.old
  5. Restart the docker service:  sudo service docker start
  6. Test that the database is working as expected (i.e. containing all the data)
  7. Delete the old docker data location: sudo rm -rf /var/lib/docker.old
