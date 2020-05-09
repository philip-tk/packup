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

# This line puts the list of backup folders into the $list variable
list=$(ssh $dest_host "cd $dest_dir; echo $src_folder*")

echo "This is the list of backup directories:"

# This for loop loops through the items in the list and prints each entry onto
# a new line.
for i in $list; do
	echo $i | tr -d '/';
done

# This reads input from the user to see how many of the previous directories
# would require deletion.
read -p "Number of directories to remove (default = 1): " removals

# Sets the default value to 1 if no input is given.
removals=${removals:-1}

echo "Directories to be removed:" $removals

# If the value of $removals is greater than 0, i.e. one or more backup
# directories require deletion, run the encases commands.
if [ "$removals" -gt 0 ]; then
	# Puts the first n fields into $delete_list where n = $removals.
	delete_list=$(echo $list | cut -f -$removals -d\ )
	# Loops over each field (backup directory) in $delete_list and removes
	# each entry recursively and forcefully.
	for i in $delete_list; do
		ssh $dest_host "rm -rf $dest_dir/$i"
	done
	echo "All done!"
else
	echo "All done!"
fi
