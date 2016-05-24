#!/bin/bash
echo 2.1
cd "`dirname "$0"`"
echo 2.2
./stop.sh
echo 2.3
./start.sh
echo 2.4
