You need to add application as authorized in xml file
Look at your own skype home directory for example

You need the following in your ~/.asoundrc
Then set skype to use mic for both input/output.

pcm.!default {
	type null
}
pcm.mic {
  type file
  slave {
    pcm "default"
  }
  file "/dev/null"
}
