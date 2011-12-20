#!/bin/bash
#
# Michael Mottola
# <mikemottola@gmail.com>
# December 18, 2011
# 
# Creates backup files (bson) of all MongoDb databases on a given server.
# Default behaviour dumps the mongo database and tars the output into a file
# named after the current date. ex: 2011-12-19.tar.gz
#

### Set server settings
HOST="localhost"
PORT="27017" # default mongoDb port is 27017
USERNAME=""
PASSWORD=""

# Set where database backups will be stored
# keyword DATE gets replaced by the current date, you can use it in either path below
BACKUP_PATH="/path/to/backup/directory" # do not include trailing slash
FILE_NAME="DATE" #defaults to [currentdate].tar.gz ex: 2011-12-19.tar.gz


##################################################################################
# Should not have to edit below this line unless you require special functionality
# or wish to make improvements to the script
##################################################################################

# Auto detect unix bin paths, enter these manually if script fails to auto detect
MONGO_DUMP_BIN_PATH="$(which mongodump)"
TAR_BIN_PATH="$(which tar)"

# Get todays date to use in filename of backup output
TODAYS_DATE=`date "+%Y-%m-%d"`

# replace DATE with todays date in the backup path
BACKUP_PATH="${BACKUP_PATH//DATE/$TODAYS_DATE}"

# Create BACKUP_PATH directory if it does not exist
[ ! -d $BACKUP_PATH ] && mkdir -p $BACKUP_PATH || :

# Ensure directory exists before dumping to it
if [ -d "$BACKUP_PATH" ]; then

	cd $BACKUP_PATH
	
	# initialize temp backup directory
	TMP_BACKUP_DIR="mongodb-$TODAYS_DATE"
	
	echo; echo "=> Backing up Mongo Server: $HOST:$PORT"; echo -n '   ';
	
	# run dump on mongoDB
	if [ "$USERNAME" != "" -a "$PASSWORD" != "" ]; then 
		$MONGO_DUMP_BIN_PATH --host $HOST:$PORT -u $USERNAME -p $PASSWORD --out $TMP_BACKUP_DIR >> /dev/null
	else 
		$MONGO_DUMP_BIN_PATH --host $HOST:$PORT --out $TMP_BACKUP_DIR >> /dev/null
	fi
	
	# check to see if mongoDb was dumped correctly
	if [ -d "$TMP_BACKUP_DIR" ]; then
	
		# if file name is set to nothing then make it todays date
		if [ "$FILE_NAME" == "" ]; then
			FILE_NAME="$TODAYS_DATE"
		fi
	
		# replace DATE with todays date in the filename
		FILE_NAME="${FILE_NAME//DATE/$TODAYS_DATE}"

		# turn dumped files into a single tar file
		$TAR_BIN_PATH --remove-files -czf $FILE_NAME.tar.gz $TMP_BACKUP_DIR >> /dev/null

		# verify that the file was created
		if [ -f "$FILE_NAME.tar.gz" ]; then
			echo "=> Success: `du -sh $FILE_NAME.tar.gz`"; echo;
	
			# forcely remove if files still exist and tar was made successfully
			# this is done because the --remove-files flag on tar does not always work
			if [ -d "$BACKUP_PATH/$TMP_BACKUP_DIR" ]; then
				rm -rf "$BACKUP_PATH/$TMP_BACKUP_DIR"
			fi
		else
			 echo "!!!=> Failed to create backup file: $BACKUP_PATH/$FILE_NAME.tar.gz"; echo;
		fi
	else 
		echo; echo "!!!=> Failed to backup mongoDB"; echo;	
	fi
else

	echo "!!!=> Failed to create backup path: $BACKUP_PATH"

fi
