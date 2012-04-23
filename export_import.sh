#!/bin/ksh
##########################################################################################
#Author: sanumala
#Date: 04-11-2012
#Description: This script can be used to export and import cdw db2 tables.
#Usage: export_import.sh talesList.txt dbconfig.properties
#Input1: talesList.txt --> contains list of tables seperated line-by-line.
#Input2: dbconfig.properties --> contains properties to connect to source and target db's.
#output: Useful echos on console and DB messages will be loged to /pwd/log_date.log.
##########################################################################################

usage()
{
	echo "Usage of this script"
	echo "export_import.sh <tables_list>.txt <dbconfig>.properties"
}

validateFileExistance()
{
	input="$@"
   # make sure file exist and readable
   if [ ! -f $input ]; then
   	echo "$input : does not exists"
   	exit 1
   elif [ ! -r $input ]; then
   	echo "$input: can not read"
   	exit 2
   fi
}

readAndStoreTableNames()
{
	BAKIFS=$IFS
	IFS=$(echo -en "\n\b")
	exec 3<&0
	exec 0<"$tableListFile"
	counter=0
	while read -r line
	do
        # Skip Header record.
		#test $counter -eq 1 && ((counter=counter+1)) && continue
		# use $line variable to process line in processTestCase() function
		tables[counter]="$line"
		counter=${counter}+1
	done
	exec 0<&3
}
#This will run multiple threads at a same time to complete extracts fast
exportData()
{
	sqlToExecute="$@"
	db2 "connect to $SOURCE_DATABASE_NAME user $SOURCE_DATABASE_USER_NAME using $SOURCE_DATABASE_PASSWORD" >> $LOG
	db2 "set schema $SOURCE_SCHEMA_NAME" >> $LOG
	db2 $sqlToExecute >> $LOG
	db2 terminate >> $LOG
	#echo "Now Executing ::::: $sqlToExecute" #>> $LOG
}

importData()
{
	sqlToExecute="$@"
	db2 "connect to $TARGET_DATABASE_NAME user $TARGET_DATABASE_USER_NAME using $TARGET_DATABASE_PASSWORD" >> $LOG
	db2 "set schema $TARGET_SCHEMA_NAME" >> $LOG
	db2 $sqlToExecute >> $LOG
	db2 terminate >> $LOG
	echo "Now Executing :::: $sqlToExecute" #>>$LOG
}



#####	  M A I N   S C R I P T   S T A R T S    H E R E	#####
tableListFile=""
dbConfigFile=""
set -A tables
numberOfTables=0
LOG_FILE=`pwd`/log_`date +"%m%d%Y"`.log
# Make sure we get file name as command line argument
if [[ $# -lt 2 ]]; then
	usage
	exit
else
	echo "Execution started at  ::: `date +\"%m-%d-%Y %T\"`"
	tableListFile="$1"
	dbConfigFile="$2"
   # make sure file exist and readable
   echo "Validating file existance for $tableListFile"
   validateFileExistance $tableListFile

   echo "Validating file existance for $dbConfigFile"
   validateFileExistance $dbConfigFile
   
   #Now Source db config properties and make them available as env variables
   . $dbConfigFile
   
   numberOfTables=`cat $tableListFile|wc -l`
   echo "Number of tables are $numberOfTables"
   
   #echo "Current working directory is `pwd`"
   readAndStoreTableNames

   for ((i=0;i<$numberOfTables;i++))
   do
    exportData "export to `pwd`/${tables[i]}.ixf of ixf select * from $SOURCE_SCHEMA_NAME.${tables[i]}" &
 done
   	#Wait until all backups are done.This very important and dont comment this line
   	wait
   	echo "Exports are completed successfully at `date +\"%m-%d-%Y %T\"`"

   	#Now import data into target
   	echo "Importing data into target($TARGET_DATABASE_NAME#$TARGET_SCHEMA_NAME) started at `date +\"%m-%d-%Y %T\"`"
   	for ((i=0;i<$numberOfTables;i++))
   	do
   		importData "import from `pwd`/${tables[i]}.ixf of ixf commitcount 10000 insert into $TARGET_SCHEMA_NAME.${tables[i]}" &
   	done
   	#Wait until restores are done
   	wait
   	echo "Export and import are completed successfully at  `date +\"%m-%d-%Y %T\"`. Please refer $LOG_FILE for more details"
   fi