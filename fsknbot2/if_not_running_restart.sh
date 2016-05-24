#!/bin/bash
cd "$(dirname -- "$0")"
echo 1
date
echo 2
. /home/daquino/.bash_profile # need rvm
echo 3
./running.sh || ./restart.sh
echo 4
