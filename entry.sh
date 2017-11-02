#!/bin/bash

user=application
group=application

if [ x"$WRITABLE_PATHS" != x ]
then

IFS=":"
for path in $WRITABLE_PATHS
do
	chown -R $user:$group "$path"
done
fi

/usr/bin/python /usr/bin/supervisord -c /opt/docker/etc/supervisor.conf --logfile /dev/null --pidfile /dev/null --user root
