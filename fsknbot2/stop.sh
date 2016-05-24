#!/bin/bash
echo 3.1
cd "$(dirname -- "$0")"
kill `cat ./run/bot.pid` || exit
sleep 5
kill `cat ./run/bot.pid` || exit
sleep 5
kill -9 `cat ./run/bot.pid`
kill -9 `cat ./run/bot.pid`
kill -9 `cat ./run/bot.pid`
kill -9 `cat ./run/bot.pid`
echo 3.2
