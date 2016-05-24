IrcCommandManager.register 'seen',
	"seen <user> => Print last time I saw the user."

IrcCommandManager.register 'seen' do |m|
	nick = m.args.first
	if nick.nil?
		m.reply "Who?"
	else
		last = Seen.last?(nick)
		if last.nil?
			m.reply "I have never seen #{nick}"
		else
			m.reply last.strftime("I last saw #{nick} at: %a %b %d %I:%M %p %Z")
		end
	end
end

# welcome plugin does this for us so we don't end up with 
# race condition

#IrcHandleLine.events[:join].register do |channel,nick|
#	Seen.set nick, Time.now if channel == "#forsaken"
#end

require 'yaml'
require 'time'
class Seen
  class << self
 
    @@db_path = "#{ROOT}/db/seen.yaml"
    @@db = File.expand_path(@@db_path)
    @@seen = (File.exists?(@@db) && YAML.load_file(@@db)) || {}

    def save
      file = File.open(@@db,'w+')
      YAML.dump(@@seen,file)
      file.close
		end

		def set nick, time
			@@seen[nick] = time.to_s
			save
		end

		def last? nick
			@@seen[nick].nil? ?
				nil :
				Time.parse(@@seen[nick])
		end

  end
end
