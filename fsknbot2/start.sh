#!/bin/bash
cd "`dirname "$0"`"
./run.rb 2>&1 >> logs/bot.log &
pid=$!
echo $pid > ./run/bot.pid
echo "started with pid $pid"
