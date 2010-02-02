IrcCommandManager.register ['markov','m'], '' do |m|
	m.reply Markov.cmd m
end

IrcChatMsg.register do |m|
	Markov.listener m
end

require 'yaml'
class Markov
class << self
 
	@@db = File.expand_path "#{ROOT}/db/words.txt"
	@@words = {}

	def read
		return unless File.exist? @@db
		File.read(@@db).split("\n").each do |line|
			children = line.split
			parent = children.shift
			@@words[parent] = {} unless @@words[parent]
			children.each do |child|
				word,count = child.split(":")
				@@words[parent][word] = count.to_i
			end
		end
	end

	def save
		file = File.open @@db, 'w'
		@@words.each do |k,v|
			file.write "#{k} "
			v.each do |k,v|
				file.write "#{k}:#{v} "
			end
			file.write "\n"
		end
		file.close
	end

	def clean
		@@words = {}
	end

=begin
	@@db = File.expand_path "#{ROOT}/db/words.yaml"
	@@words = (File.exists?(@@db) && YAML.load_file(@@db)) || {}
	def save
		file = File.open(@@db,'w+')
		YAML.dump(@@words,file)
		file.close
	end

	def dump
		@@words.each do |k,v|
			puts k
			v.each do |k,v|
				puts "\t#{k} => #{v}"
			end
		end
	end
=end

	def cmd m
		return if m.channel =~ /forsaken/
#		return unless m.user.nick =~ /methods/
		case m.args.first
		when "fskn"
			output = chat
			IrcConnection.privmsg "#forsaken", output
			return
		when "chat" then chat
		when "clean" then clean
		when "read"
			file = m.args[1]
			lines = File.read(file).split("\n")
			lines.each_with_index do |line,i| 
				analyze line.split
				puts "reading line #{i}"
			end
=begin
			puts "cleaning off counts of 1"
			ones = {}
			@@words.each do |parent,children|
				children.each do |child,count|
					next unless count == 1
					ones[parent] = [] if ones[parent].nil?
					ones[parent].delete 
				end
			end
=end
			puts "saving file"
			save
			"read #{lines.length} lines from #{file}; top level word list now #{@@words.length} long"
		else "commands: chat read clean fskn"
		end
	end

	def rand_word
		words = @@words.keys
		words[rand(words.length)]
	end

	def best_child parent
		words = @@words[parent]
		return if words.nil?
		best_word = ""
		best_count = 0
		words.each do |word,count|
			if count > best_count
				best_count = count
				best_word = word
			end
		end
		best_word
	end

	def rand_child parent
		words = @@words[parent]
		return if words.nil?
		words = words.keys
		words[ rand(words.length) ]
	end

	def chat
		output = []
		output << rand_word
		rand(20).times {
			child1 = best_child(output.last)
			child2 = rand_child(output.last)
			child = [child1,child2][rand(2)]
			if child.nil?
				puts "hit dead end on word #{child}"
				break
			end
			output << child
		}
		output.join(' ')
	end
  
	def listener m
		return if m.from.nick =~ /bot/
		analyze m.message.split
	end

	def analyze words
		words.length.times do |i|
			_word = words[i]
			_next = words[i+1]
			break if _next.nil?
			next unless _word =~ /^[a-zA-Z]+$/
			next unless _next =~ /^[a-zA-Z]+$/
			@@words[_word] = {} if @@words[_word].nil?
			@@words[_word][_next] = 0 if @@words[_word][_next].nil?
			@@words[_word][_next] += 1
			puts "#{_word} => #{_next} = #{@@words[_word][_next]}"
		end
#		save
	end

end
end
Markov.read

puts "markov plugin loaded"
