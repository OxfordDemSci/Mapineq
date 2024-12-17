#!/bin/bash

# creates a local backup of remote SQL database using the pg_dump utility
# restore using:  pg_restore -Fc --clean --host=localhost --username=postgres --dbname=dgg /research/backup/mapineq_db/mapineq.dump

# backup directory
base_dir=~/home/doug/ndph/J/backup/mapineq_db
past_backups=($(ls ${base_dir}))
current_date=$(date +"%Y%m%d")
backup_dir=${base_dir}/${current_date}
dump_file=${backup_dir}/mapineq.dump

# make directory
mkdir -p ${backup_dir}

# initialise log file
log_file=${backup_dir}/log.txt
printf "[`date +'%Y-%m-%d %H:%M:%S'`] ${dump_file}\n" >> ${log_file}

# remote dump
/usr/lib/postgresql/15/bin/pg_dump -h 15.236.82.244 -U postgres -Fc mapineq > ${dump_file}

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

