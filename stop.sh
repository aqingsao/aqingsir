#!/bin/bash
pid=`cat /var/run/aqingsir/aqingsir.pid`
echo "stopping aqingsir with pid $pid..."
kill -9 $pid