class IrcCommandManager
  class << self

    @@help = {}; def help; @@help; end
    @@commands = {}; def commands; @@commands; end
		@@aliases = {}; def aliases; @@aliases; end

    def call command, msg
      return unless @@commands[ command ]
			t = Time.now
      rv = @@commands[ command ].call(msg.dup)
			puts "Took #{Time.now - t} to run command: #{command}"
			rv
    end

    # register both at once or one at a time
    def register commands, help=nil, &block
			main = [commands].flatten.first
			@@aliases[main] = []
      [commands].flatten.each_with_index do |command,i|
        @@help[ command ] = help unless help.nil?
        @@commands[ command ] = block if block_given?
				@@aliases[main] << command if i > 0
      end
    end

  end
end
