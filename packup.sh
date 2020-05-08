#!/bin/sh

# Reads config file and sets variables.
dest_host=$(grep host .packuprc | cut -f 2 -d\ )
dest_port=$(grep port .packuprc | cut -f 2 -d\ )
dest_dir=$(grep dest-dir .packuprc | cut -f 2 -d\ )
src_dir=$(grep src-dir .packuprc | cut -f 2 -d\ )

# DTG stands for date-time-group.
# This formats the date as YYYY-MM-DD.
DTG=$(date +%Y-%m-%d)

# This uses the last.dir file that is populated at the end of the script to
# get the name of the last backup directory.
LASTBACKUP=$(cat $dest_dir/last.dir)

# This line puts the file name of the last backup in a file called last.dir
# which means it can then be used by the LASTBACKUP variable at the start
# of the script. It is meant to be at the end of the shellscript.
echo $dest_dir/$(echo $src_dir | grep -o '[^/]*$')-$DTG > $dest_dir/last.dir
