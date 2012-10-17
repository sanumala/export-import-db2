#!/bin/bash
#
# Run-level Startup script for the DB2 Instance
#
### BEGIN INIT INFO
# Provides:          DB2 Express C 10.1
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Startup/Shutdown DB2 Instance
### END INIT INFO
DB2_USER=db2inst1
DB2_USER_DIR=/home/db2inst1
if [ ! -f $DB2_USER_DIR/sqllib/adm/db2start ]
	then
	echo "DB2 might not have been installed and cannot be started!"
	exit 1
fi
# depending on parameter -- startup, shutdown, restart
# of the instance and listener or usage display
case "$1" in
start)
#DB2 Instance startup
echo -n "Starting DB2 Instance: "
su - $DB2_USER -c ". $DB2_USER_DIR/sqllib/db2profile"
su - $DB2_USER -c "$DB2_USER_DIR/sqllib/adm/db2start"
ret=$? 
    if [ $ret -eq 0 ]
    then
            echo "DB2 Instance Started Successfully!"
    else
            echo "DB2 Instance Failed!"
            exit 1
    fi
touch /var/lock/db2
echo "OK"
;;
stop)
# DB2 instance shutdown
echo -n "Shutdown DB2 instance: "
su - $DB2_USER -c "$DB2_USER_DIR/sqllib/adm/db2stop"
ret=$?
    if [ $ret -eq 0 ]
    then
            echo "DB2 Shutdown Successful"
    else
            echo "DB2 Shutdown Failed"
            exit 1
    fi
rm -f /var/lock/db2
echo "OK"
;;
reload|restart)
$0 stop
$0 start
;;
*)
echo "Usage: $0 start|stop|restart|reload"
exit 1
esac
exit 0