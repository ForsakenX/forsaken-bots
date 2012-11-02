#!/bin/bash
function die { echo "$@" >&2; exit 1; }
function success { echo "$@" >&2; exit 0; }

cd "$(dirname -- "$0")" ||
	die "could not cd to my own folder"

pid=$(cat "./run/bot.pid"); [[ $pid ]] ||
	die "pid file empty or does not exist"

cwd=$(readlink /proc/$pid/cwd); [[ $cwd == $PWD ]] ||
	die "process not running or process does not look like bot"

success "bot ($pid) found running in: $cwd"
