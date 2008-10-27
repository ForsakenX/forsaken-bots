#!/usr/bin/env python

# /***** BEGIN LICENSE BLOCK****
#  Version: MPL 1.1/GPL 2.0/LGPL 2.1
# 
#  The contents of this file are subject to the Mozilla Public License Version
#  1.1 (the "License"); you may not use this file except in compliance with
#  the License. You may obtain a copy of the License at
#  http://www.mozilla.org/MPL/
# 
#  Software distributed under the License is distributed on an "AS IS" basis,
#  WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
#  for the specific language governing rights and limitations under the
#  License.
# 
#  The Original Code is skypebot.
# 
#  The Initial Developer of the Original Code is Daniel Aquino.
#  Portions created by the Initial Developer are Copyright (C) 2008
#  the Initial Developer. All Rights Reserved.
# 
#  Contributor(s):
#    Daniel Aquino <mr.danielaquino@gmail.com> aka methods
# 
#  Alternatively, the contents of this file may be used under the terms of
#  either the GNU General Public License Version 2 or later (the "GPL"), or
#  the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
#  in which case the provisions of the GPL or the LGPL are applicable instead
#  of those above. If you wish to allow use of your version of this file only
#  under the terms of either the GPL or the LGPL, and not to allow others to
#  use your version of this file under the terms of the MPL, indicate your
#  decision by deleting the provisions above and replace them with the notice
#  and other provisions required by the GPL or the LGPL. If you do not delete
#  the provisions above, a recipient may use your version of this file under
#  the terms of any one of the MPL, the GPL or the LGPL.
# 
# **** END LICENSE BLOCK****/

#
# Name
#
# 	skypebot
#
# Synopsis
#
# 	Skype side kick for FsknBot	
#
# Roles
#
#	a) Manage central conference line for Forsaken community
#	b) Broadcast mood and online status changes to forsaken chat
#	c) Advertise forsaken on skype network with info and greeting
#
# Documentation
#
#	Skype4Py http://skype4py.sourceforge.net/doc/html/
#

#
# libraries
#


import Skype4Py
import sys
import time
import socket
import re



#
#  Connection to #forsaken proxy
#


# state of connection
fskn_connected = False;


# tcp socket object
fskn_sock = socket.socket();


# connect to methproxy
try:
	fskn_sock.connect(('localhost',6667));
	fskn_connected = True;
except Exception, e:
	print "Could not connect to forsaken chat: ", e;


# send a message helper
def fskn_chat(msg):

	# bank if message is empty or we are not connected
	if not (msg and fskn_connected): return;

	# send to forsaken chat
	fskn_sock.send('privmsg #forsaken :skype: '+irc_sanatize(msg)+'\n');

	# print to console
	print msg;

# clean up message
def irc_sanatize(msg):

	# replace all white space with single space
	return re.compile('\s').sub( ' ', msg );


#
#  The Bot
#


# handles incoming calls
def incoming_call( Call ):
	
	# get the first call
	existing_call = first_active_call(skype.ActiveCalls);

	# check to see if this is not the first call
	if Call != existing_call:

		# join or create a conference
		conference = Call.Join( existing_call.Id );

	# answer the call
	Call.Answer();

	# get rid of call from event list
	Call.MarkAsSeen();

	# send message to forsaken
	fskn_chat( Call.PartnerDisplayName + " has joined the conference." );


# handle end of call
def finished_call( Call ):

	# send message to forsaken
	fskn_chat( Call.PartnerDisplayName + " has left the conference." );



# handles incoming messages from other users
def incoming_message( Message ):

	# display the message
	print(Message.FromDisplayName +': '+Message.Body);

	# talk back client
	# skype.SendMessage( Message.FromHandle, "You said: "+Message.Body );

	# Greeting
	skype.SendMessage( Message.FromHandle,
		".\n"+
		"Hello " + Message.FromDisplayName + "!  I am the Forsaken Bot!\n"+
		"Forsaken is a 6 degree of freedom multiplayer online game based on Descent.\n"+
		"You see the game in action here: http://www.youtube.com/watch?v=e6u81paVpps\n"+
		"More information is available at http://forsakenplanet.tk\n"+
		"The main lobby is on irc.freenode.net channel #forsaken.\n"+
		"To join the Forsaken conference line simply call me and I'll let you in!"
	);



# user has appeared online
def user_online( User ):

	# send message to forsaken chat
	fskn_chat( name( User ) + " has appeared online." );


# user has gone offline
def user_offline( User ):

	# send message to forsaken chat
	fskn_chat( name( User ) + " has gone offline." );


# user mood has changed
def user_mood( User, Mood ):

	# send message to forsaken chat
	fskn_chat( name( User ) + "'s mood: " + Mood );


# a user has asked to be friends
def user_auth_request( User ):

	# print to console
	print "-- Got Auth Request: ", User.Handle;

	# for each user waiting authorization
	for user in skype.UsersWaitingAuthorization:

		# allow them to be friend
		user.BuddyStatus = 3;
		user.IsAuthorized = True;



#
#  Skype
#


# helper to get the name of a user object
def name( User ):

	# this fails in this stack unless already cached !!
	#User.DisplayName;
	return User.FullName or User.Handle;


# first real call
# sometimes finished calls are still in the active list
def first_active_call( ActiveCalls ):
	for call in ActiveCalls:
		if not call.Status == "FINISHED":
			return call;



# attach to skype process helper
def attach():

	# try to attach
	try:

		# attach to skype
		skype.Attach();
		return True;

	# we had a serious failure trying to connect
	# most likely skype is not running (is DISPLAY set?)
	except Skype4Py.errors.ISkypeAPIError, e:

		# print message to console
		print "Error Attaching to Skype: ", e;
		return False;



# listener for "attach to skype" events
def OnAttach(status):

	# print attach result (success/failure) to the screen
	print 'API attachment status: '+skype.Convert.AttachmentStatusToText(status)

	# if attach was NOT successfull
	if status != Skype4Py.apiAttachSuccess:

		# this is letting us know we are not attached but could be
		if status == Skype4Py.apiAttachAvailable:

			# try to attach 
			while ( not attach() ):

				# sleep 5 seconds between attempts
				time.sleep(5);



# listener for message events
def OnMessageStatus(Message,Status):

	# we have received a message
	if Status == 'RECEIVED':

		# send the message to our bot
		incoming_message( Message );



# listener for call events
def OnCallStatus(Call,Status):

	# a call is ringing
	if Status == 'RINGING':

		# we have a new call
		if Call.Type.split('_')[0] == "INCOMING":

			# send to bot
			incoming_call( Call );

	# call has finished
	if Status == "FINISHED":

		# send to bot
		finished_call( Call );



# a user's online status has changed
def OnOnlineStatus( User, Status ):

	# ignore my own status
	if User.Handle == 'fsknbot': return;

	# user has gone offline
	if Status == "OFFLINE":

		# send to bot
		user_offline( User );

	# user has signed online
	if Status == "ONLINE" and UserStates[ User.Handle ] == "OFFLINE":

		# send to bot
		user_online( User );

	# update saved state
	UserStates[ User.Handle ] = User.OnlineStatus;


# a user is asking for authorization
def OnUserAuthorizationRequestReceivedStatus( User ):

	# send to the bot
	user_auth_request( User );


# on user mood change
def OnUserMood( User, Mood ):

	# send to bot
	user_mood( User, Mood );



# create the skype object
try: skype = Skype4Py.Skype();
except Skype4Py.errors.ISkypeAPIError, e:
	print "Error creating skype object: ", e;
	exit(1);

# set debug on
skype.ApiDebugLevel = 1;

# set bot name
skype.FriendlyName = "FsknBot";

# assign listeners
skype.OnAttachmentStatus = OnAttach;
skype.OnMessageStatus = OnMessageStatus;
skype.OnCallStatus = OnCallStatus;
skype.OnOnlineStatus = OnOnlineStatus;
skype.OnAuthorizationRequestReceivedStatus = OnUserAuthorizationRequestReceivedStatus;
skype.OnUserMood = OnUserMood;


# attach to the running skype
attach();

# set auto away off
#skype.Settings.AutoAway = False;

# list of last user state
UserStates = {};

# for each friend
for friend in skype.Friends:

	# collect initial states
	UserStates[ friend.Handle ] = friend.OnlineStatus;


#
#  Loop
#

while 1:1;

#
#  Cleanup
#


# close fskn chat socket
fskn_sock.close();


