
# stop first
./stop.sh

# start fake desktop
Xvfb :0 &> log/xfvb.log &

# set display
export DISPLAY=:0.0

# start skype
echo fsknbot PASSWORD | skype --enable-dbus --use-session-dbus --pipelogin &> log/skype.log &

# give time to startup
sleep 5

# start bot
./skypebot.py

