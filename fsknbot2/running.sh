#!/bin/bash

echo 1.1

function die { echo "$@" >&2; exit 1; }
function success { echo "$@" >&2; exit 0; }

echo 1.2
cd "$(dirname -- "$0")" ||
	die "could not cd to my own folder"

echo 1.3
pid=$(cat "./run/bot.pid"); [[ $pid ]] ||
	die "pid file empty or does not exist"

echo 1.4
cwd=$(readlink /proc/$pid/cwd); [[ $cwd == $PWD ]] ||
	die "process not running or process does not look like bot"

echo 1.5
success "bot ($pid) found running in: $cwd"
