#!/bin/bash
cd "$(dirname -- "$0")"
kill `cat ./run/bot.pid` || exit
sleep 5
kill `cat ./run/bot.pid` || exit
sleep 5
kill -9 `cat ./run/bot.pid`
kill -9 `cat ./run/bot.pid`
kill -9 `cat ./run/bot.pid`
kill -9 `cat ./run/bot.pid`
