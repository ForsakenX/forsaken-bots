require "rexml/document"

IrcCommandManager.register 'times',
"times => Print meetings; " +
"times [message] => Create a new time"

IrcCommandManager.register 'times' do |m|
  m.reply GameTimes.run m
end

require 'yaml'
require 'time'
class GameTimes
  class << self
 
    @@db_path = "#{ROOT}/db/times.yaml"
    @@db = File.expand_path(@@db_path)
    @@times = (File.exists?(@@db) && YAML.load_file(@@db)) || []

    def save_db
      file = File.open(@@db,'w+')
      YAML.dump(@@times,file)
      file.close
		end

		def save_xml
      doc = REXML::Document.new
      times = doc.add_element("times")
	    @@times.sort{|a,b|
				Time.parse(a[:at]) <=> Time.parse(b[:at])
			}.map{|t|
        times.add_element("time",{ 
					"nick" => t[:from], 
					"time" => Time.parse(t[:at]).to_i
				})
      }
      begin
        file = File.open( File.expand_path( "#{ROOT}/db/times.xml" ), 'w+' )
        file.write doc
        file.close
      rescue Exception
      	puts "Error Saving times.xml: #{$!}"
      end
    end

		def save
			save_db
			save_xml
    end

    def run m
      if m.args.first.nil?
				show_all
			else
				create m
				""
			end
    end

 		def show_all
			if @@times.length > 0
				filter_old
		    @@times.sort{|a,b|
					Time.parse(a[:at]) <=> Time.parse(b[:at])
				}.map{|t|
					t[:from] + " wants to play on " + 
					Time.parse(t[:at]).strftime("%a %b %d %I:%M %p %Z")
				}.join('; ')
			else
				"no times exist"
			end
		rescue
			"failed to show times: "+ $!
		end

		def filter_old
			@@times = @@times.select{|t| Time.parse(t[:at]).to_i >= Time.now.to_i-60*60 }
			save
		rescue
			puts "failed to filter_old"
		end

		def create m
			t = {
				:from => m.from.nick, 
				:time => Time.now.to_s,
				:at   => Time.parse(m.args.join(' ')).to_s,
				:says => m.args.join(' ')
			}
			@@times << t
			save
      IrcConnection.privmsg IrcUser.nicks,
				"#{t[:from]} created a new meet time at #{
					Time.parse(t[:at]).strftime("%a %b %d %I:%M %p %Z")}",
				"NOTICE"
		rescue
			"failed to created time: " + $!
		end

  end
end
