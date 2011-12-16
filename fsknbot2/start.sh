#!/bin/bash
cd "`dirname "$0"`"
./run.rb 2>&1 >> log &
pid=$!
echo $pid > /home/aquinod/run/bot.pid
echo "started with pid $pid"
