#!/usr/bin/env python

import Skype4Py
import time
import code
import sys
import rlcompleter
import readline

# add tab completion to console
readline.parse_and_bind("tab: complete")

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
	if status == Skype4Py.apiAttachSuccess: return;

	# this is letting us know we are not attached but could be
	if status != Skype4Py.apiAttachAvailable: return;

	# try to attach every 5 seconds
	while ( not attach() ): time.sleep(5);


# create the skype object
try: skype = Skype4Py.Skype();
except Skype4Py.errors.ISkypeAPIError, e:
	print "Error creating skype object: ", e;
	exit(1);

# Redirect standard error so debug gets off my console
#sys.stderr = open("console.log","w",0);

# set debug on
#skype.ApiDebugLevel = 1;

# set bot name
skype.FriendlyName = "Console";

# assign listeners
skype.OnAttachmentStatus = OnAttach;

# attach to the running skype
attach();

# keep the program alive in a console
# pass in the skype object so we can work with it
console = code.InteractiveConsole({'skype':skype});
console.interact();


