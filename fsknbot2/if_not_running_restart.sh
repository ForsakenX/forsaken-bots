#!/bin/bash
cd "$(dirname -- "$0")"
date
. /home/daquino/.bash_profile # need rvm
./running.sh || ./restart.sh
