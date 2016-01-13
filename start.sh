jekyll serve --detach
echo `ps -ef | grep jekyll | grep -v grep | awk '{print $2}' ` > /var/run/aqingsir/aqingsir.pid
echo 'start successfully'