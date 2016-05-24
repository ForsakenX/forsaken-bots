#!/bin/bash
echo 4.1
cd "`dirname "$0"`"
./run.rb 2>&1 >> logs/bot.log &
pid=$!
echo $pid > ./run/bot.pid
echo "started with pid $pid"
echo 4.2
