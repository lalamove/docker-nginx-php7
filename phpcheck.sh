#!/bin/bash

while ! nc -w 1 127.0.0.1 9000 2>/dev/null
do
	echo "PHP not yet running, waiting"
	sleep 1s
done

/usr/sbin/nginx  -g 'daemon off;'


