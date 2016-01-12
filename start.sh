jekyll serve --detach
pid=$!
echo $pid > /var/run/aqingsir/aqingsir.pid

echo "start aqingsir with pid $pid"