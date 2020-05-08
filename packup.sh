#!/bin/sh

# Reads config file and sets variables.
dest_host=$(grep host .packuprc | cut -f 2 -d\ )
dest_port=$(grep port .packuprc | cut -f 2 -d\ )
dest_dir=$(grep dest-dir .packuprc | cut -f 2 -d\ )
src_dir=$(grep src-dir .packuprc | cut -f 2 -d\ )

# DTG stands for date-time-group
# This formats the date as YYYY-MM-DD.
DTG=$(date +%Y-%m-%d)

echo $dest_dir$DTG > $dest_dir/last.dir
