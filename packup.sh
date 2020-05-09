#!/bin/sh

# Reads config file and sets variables.
dest_host=$(grep host .packuprc | cut -f 2 -d\ )
dest_dir=$(grep dest-dir .packuprc | cut -f 2 -d\ )
src_dir=$(grep src-dir .packuprc | cut -f 2 -d\ )

# This line is to assign the name of the folder being backed up to a variable
# as this string needs to be used multiple times, it is better for code length
# as well as one time execution.
src_folder=$(echo $src_dir | grep -o '[^/]*$')

# DTG stands for date-time-group.
# This formats the string as YYYY-MM-DD@HHMMhrs.
DTG=$(date +%Y-%m-%d@%H%M'hrs')

# This uses the last.dir file that is populated at the end of the script to
# get the name of the last backup directory.
LASTBACKUP=$(ssh $dest_host "cat $dest_dir/last.dir")

# This is the main backup machine, it uses this format to push files to the
# server: rsync [OPTIONS...] SRC... [USER@]HOST:DEST
# as described by the rsync man-page.
# It backs up the source directory to the destination directory with the
# '-Incomplete' suffix. This allows a backup to be cut and resumed.
# Clean up on the file name is done later.
rsync -Phaze "ssh" --link-dest="$LASTBACKUP/" \
        "$src_dir/" "$dest_host:$dest_dir/$src_folder-Incomplete"
# This is the breakdown of the options applied in the above line:
#          -P: Shows the progress of the file transfer.
#          -h: Shows the progress in human-readable format.
#          -a: Transfers files recursively, preserving everything 
#              except hardlinks.
#          -z: Compresses the file data as it is being transferred.
#              More CPU usage, less network usage.
#          -e: Indicates the remote shell to use.
# --link-dest: Hardlinks to the last backup directory when files are unchanged.

# This line cleans up the backup folder name upon successful completion.
ssh $dest_host \
        "mv $dest_dir/$src_folder-Incomplete $dest_dir/$src_folder-$DTG"

# This line puts the file name of the last backup in a file called last.dir
# which means it can then be used by the LASTBACKUP variable at the start
# of the script. It is meant to be at the end of the shellscript.
ssh $dest_host "echo $dest_dir/$src_folder-$DTG > $dest_dir/last.dir"
