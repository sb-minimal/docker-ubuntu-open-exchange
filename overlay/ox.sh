#!/bin/bash


DB_PASSWORD=${DB_PASSWORD:-db_password}
ADMIN_MASTER_PASSWORD=${ADMIN_MASTER_PASSWORD:-admin_master_password}
ADMIN_PASSWORD=${ADMIN_PASSWORD:-admin}
ADMIN_EMAIL=${ADMIN_EMAIL:-admin@example.com}

	#Memory JVM in MB
MAX_MEMORY_FOR_JAVAVM=${MAX_MEMORY_FOR_JAVAVM:-1024}

	#Filestore size in MB
FILESTORE_SIZE=${FILESTORE_SIZE:-1000000}

/etc/init.d/mysql start
sleep 10

if [ ! -e /data/initialized ]; then
	echo "/opt/open-xchange/sbin/initconfigdb --configdb-pass=$DB_PASSWORD -a"
	/opt/open-xchange/sbin/initconfigdb --configdb-pass=$DB_PASSWORD -a
	echo "/opt/open-xchange/sbin/oxinstaller --no-license --servername=oxserver --configdb-pass=$DB_PASSWORD --master-pass=$ADMIN_MASTER_PASSWORD --network-listener-host=localhost --servermemory $MAX_MEMORY_FOR_JAVAVM"
	/opt/open-xchange/sbin/oxinstaller --no-license --servername=oxserver --configdb-pass=$DB_PASSWORD --master-pass=$ADMIN_MASTER_PASSWORD --network-listener-host=localhost --servermemory $MAX_MEMORY_FOR_JAVAVM
	touch /data/initialized
fi


/etc/init.d/open-xchange start
sleep 10

	#wait for open-xchange to get ready...
for I in 1 2 3 4 5; do
	echo "sleep $I..."
	while ! nc -z -w 600 localhost 8009; do
		sleep 1
		echo "..."
	done
	sleep 1
done

if [ ! -d /data/filestore ]; then
	mkdir -p /data/filestore
	chown open-xchange:open-xchange /data/filestore
	
	/opt/open-xchange/sbin/registerserver -n oxserver -A oxadminmaster -P $ADMIN_MASTER_PASSWORD
	/opt/open-xchange/sbin/registerfilestore -A oxadminmaster -P $ADMIN_MASTER_PASSWORD -t file:/data/filestore -s $FILESTORE_SIZE
	/opt/open-xchange/sbin/registerdatabase -A oxadminmaster -P $ADMIN_MASTER_PASSWORD -n oxdatabase -p $DB_PASSWORD -m true
	
		#create admin
	/opt/open-xchange/sbin/createcontext -A oxadminmaster -P $ADMIN_MASTER_PASSWORD -c 1 -u oxadmin -d "Context Admin" -g Admin -s User -p $ADMIN_PASSWORD -L defaultcontext -e $ADMIN_EMAIL -q 1024 --access-combination-name=groupware_standard
	
		#create testuser
	/opt/open-xchange/sbin/createuser -c 1 -A oxadmin -P $ADMIN_PASSWORD -u testuser -d "Test User" -g Test -s User -p secret -e testuser@example.com --imaplogin testuser --imapserver 127.0.0.1 --smtpserver 127.0.0.1
fi

/etc/init.d/apache2 start

while sleep 10; do
	echo ""
done

/etc/init.d/apache2 stop
/etc/init.d/open-xchange stop
/etc/init.d/mysql stop

