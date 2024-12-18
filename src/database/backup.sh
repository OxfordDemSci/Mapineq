#!/bin/bash

# creates a local backup of remote SQL database using the pg_dump utility
# restore using:  pg_restore -Fc --clean --host=db_host --username=db_user --dbname=db_database /backup/mapineq.dump

# backup directory
base_dir=$1
past_backups=($(ls ${base_dir}))
current_date=$(date +"%Y%m%d")
backup_dir=${base_dir}/${current_date}
dump_file=${backup_dir}/mapineq.dump

# database details
db_host=$2
db_user=$3
db_database=$4

# make directory
mkdir -p ${backup_dir}

# initialise log file
log_file=${backup_dir}/log.txt
printf "[`date +'%Y-%m-%d %H:%M:%S'`] ${dump_file}\n" >> ${log_file}

# remote dump
pg_dump -h ${db_host} -U ${db_user} -Fc ${db_database} > ${dump_file}

# compress
printf "[`date +'%Y-%m-%d %H:%M:%S'`] Compressing (gzip)\n" >> ${log_file}
gzip -f ${dump_file}

# delete backups older than 180 days
for i in "${past_backups[@]}"
do
  let x=(`date +%s -d ${current_date}`-`date +%s -d ${i}`)/86400
  if [ $x -ge 180 ]; then
    printf "[`date +'%Y-%m-%d %H:%M:%S'`] Deleting backup (${x} days old): ${i}\n" >> ${log_file}
    rm -R ${base_dir}/${i}
  fi
done


# cleanup
unset x; unset i
unset backup_dir

printf "[`date +'%Y-%m-%d %H:%M:%S'`] Completed\n\n" >> ${log_file}

